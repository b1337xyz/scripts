#!/usr/bin/env python3
from bs4 import BeautifulSoup as BS
from optparse import OptionParser
from pathlib import Path
from random import random
from time import sleep
from xmlrpc.client import ServerProxy, Binary
from urllib.parse import unquote
import sqlite3 as sql
import requests
import json
import re
import os


def parse_arguments():
    parser = OptionParser(usage='usage: %prog [option]... URL...')
    parser.add_option('-d', dest='dir', metavar='PATH',
                      help='Download directory')
    parser.add_option('-i', dest='input_file', metavar='FILE',
                      help='Download URLs found in FILE')
    parser.add_option('-c', dest='cookie', default='',
                      help='Cookie string')
    parser.add_option('-C', dest='cookie_file', default='', metavar='FILE',
                      help='Load cookies from file (WIP)')
    parser.add_option('-A', dest='user_agent', default='', metavar='UA',
                      help='User Agent from when you got your cookies')
    opts, args = parser.parse_args()
    if not args and not opts.input_file:
        parser.print_help()
        exit(1)
    return opts, args


def path_from_env(env, fallback):
    return Path(os.getenv(env, fallback))


class Downloader:
    def __init__(self):
        opts, args = parse_arguments()
        home = Path.home()
        cache_dir = path_from_env('XDG_CACHE_HOME', home / '.cache')
        config_dir = path_from_env('XDG_CONFIG_HOME', home / '.config')
        dl_dir = path_from_env('XDG_DOWNLOAD_DIR', home / 'Downloads')

        self.config_file = config_dir / 'nhentai.json'
        self.history_file = cache_dir / 'nhentai_history'
        self.domain = 'nhentai.net'
        self.config = {  # default settings
            'dir': str(home / dl_dir / 'nhentai'),
            'cookie_file': opts.cookie_file,
            'cookie': opts.cookie,
            'rpc_host': 'http://localhost',
            'rpc_port': 6800,
            # MAKE SURE YOU USE THE SAME USERAGENT
            # AS WHEN YOU GOT YOUR COOKIE!
            'user_agent': 'Mozilla/5.0'
        }
        self.load_config()  # overwrites self.config

        if opts.cookie:
            self.config['cookie'] = opts.cookie
        if opts.cookie_file:
            self.config['cookie_file'] = opts.cookie_file
        if opts.user_agent:
            self.config['user_agent'] = opts.user_agent
        if opts.input_file:
            args = self.load_urls_from_file(opts.input_file)

        self.cookie_file = self.config.get('cookie_file')
        self.cookie = self.config.get('cookie')
        if not self.cookie_file and not self.cookie:
            self.cookie = input('Cookie: ')

        self.dir = Path(opts.dir if opts.dir else self.config.get('dir'))
        self.rpc_host = self.config.get('rpc_host')
        self.rpc_port = self.config.get('rpc_port')
        self.user_agent = self.config.get('user_agent')
        self.urls = [i.strip() for i in args if self.domain in i]

        self.start_session()
        self.save_config()
        self.rpc = ServerProxy(f'{self.rpc_host}:{self.rpc_port}/rpc').aria2

    def save_config(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=4)

    def load_config(self):
        try:
            with open(self.config_file, 'r') as f:
                self.config.update(json.load(f))
        except Exception as err:
            print(f'Error loading config file, {err}, using default settings.')

    def start_session(self):
        self.session = requests.Session()
        self.session.headers.update({'user-agent': self.user_agent})
        self.load_cookies()

    def get_cookies_from_browser(self):
        # TODO: for now this function only supports
        #       chromium based browsers (WIP)

        con = sql.connect(f'file:{self.cookie_file}?nolock=1', uri=True)
        cur = con.cursor()
        cur.execute("""
            SELECT host_key, name, value FROM cookies
            WHERE host_key LIKE '%nhentai%';
        """)
        return cur.fetchall()

    def load_cookies(self):
        if os.path.exists(self.cookie_file):
            cookies = self.get_cookies_from_browser()
            for domain, name, value in cookies:
                self.session.cookies.set(name, value, domain=domain)
        else:
            for cookie in self.cookie.split(';'):
                name, value = map(str.strip, cookie.split('='))
                self.session.cookies.set(name, value, domain=self.domain)

    def load_urls_from_file(self, file):
        with open(file, 'r') as f:
            return f.readlines()

    def download(self, url, file):
        if file.exists():
            with open(file, 'rb') as f:
                data = f.read()
        else:
            att = 0
            max_attempts = 5
            while (att := att + 1) <= max_attempts:
                r = self.session.get(url, stream=True)
                content_type = r.headers.get('content-type', '')
                if re.search(r'torrent|octet', content_type):
                    break
            else:
                print('HTTP ERROR', r.status_code)
                return

            data = r.raw.read()
            open(file, 'wb').write(data)

        self.rpc.addTorrent(Binary(data), [], {
            'rpc-save-upload-metadata': 'false',
            'force-save': 'false',
            'dir': str(file.parent)
        })

    def get_soup(self, url):
        print(f'GET: {url}')
        sleep(random() * .55)
        r = self.session.get(url)
        return BS(r.text, 'html.parser')

    def get_posts(self, url, page=0):
        posts = []
        while (page := page+1):
            soup = self.get_soup(url.format(page))
            for div in soup.find_all('div', class_='gallery'):
                if 'english' not in div.text.lower():
                    continue
                href = div.a.get('href')
                posts.append(f'https://{self.domain}{href}download')

            if soup.find('a', class_='last') is None:
                return posts

    def parse_url(self, url):
        if (match := re.match(r'.*nhentai.net/(\w+/[^/]+)', url)):
            return match.group(1)

        if (match := re.match(r'.*[\?&]q=([^&]+)', url)):
            return 'search/{}'.format(unquote(match.group(1)))

    def run(self):
        for url in self.urls:
            open(self.history_file, 'a').write(f'{url}\n')
            path = self.parse_url(url)
            if path:
                dl_dir = self.dir / path
            dl_dir.mkdir(parents=True, exist_ok=True)

            if 'page=' in url:
                url = re.sub(r'([\?&]page=)\d*', r'\1{}', url)
            else:
                url += '&page={}' if '?' in url else '?page={}'

            posts = self.get_posts(url)
            print(f'posts found: {len(posts)}')
            for url in posts:
                fname = url.split('/')[-2] + '.torrent'
                self.download(url, dl_dir / fname)


if __name__ == '__main__':
    Downloader().run()
