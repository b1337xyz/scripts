#!/usr/bin/env python3
from bs4 import BeautifulSoup as BS
from optparse import OptionParser
from time import sleep
import json
import os
import re
import requests
import subprocess as sp
import xmlrpc.client

# MAKE SURE YOU USE THE SAME IP AND USERAGENT AS WHEN YOU GOT YOUR COOKIE!
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.cache/nhentai_history')
CONFIG = os.path.join(HOME, '.config/nhentai.json')
DL_DIR = os.path.join(HOME, 'Downloads/nhentai')
DOMAIN = 'nhentai.net'
ICON = f'{HOME}/Pictures/icons/nhentai.png'
ICON = ICON if os.path.exists(ICON) else 'folder-download'
MAX_ATTEMPTS = 10


def parse_arguments():
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option('-d', '--dir', dest='dl_dir', default=DL_DIR,
                      metavar='DIR', help='download directory')
    parser.add_option('-i', '--input-file', dest='input_file', metavar='FILE',
                      action='store', help='Download URLs found in FILE')
    parser.add_option('--overwrite', action='store_true')
    opts, args = parser.parse_args()
    if len(args) == 0 and not opts.input_file:
        parser.error('<url> not provided')
    return opts, args


def notify(msg):
    try:
        sp.Popen(['notify-send', '-i', ICON, 'nhentai-dl', msg])
    except Exception:
        pass


def download(session, url, dl_dir, fname):
    file = os.path.join(dl_dir, fname)
    if not os.path.exists(file):
        att = 0
        while att < MAX_ATTEMPTS:
            r = session.get(url, stream=True)
            if r.status_code == 200:
                with open(file, 'wb') as fp:
                    fp.write(r.raw.read())
                break
            print(url, r.status_code, f'retrying... [{att}/{MAX_ATTEMPTS}]')
            sleep(15)
    return file


def get_soup(session, url):
    att = 0
    while att < MAX_ATTEMPTS:
        r = session.get(url)
        if r.status_code == 200:
            return BS(r.content, 'html.parser')
        print(url, r.status_code, f'retrying... [{att}/{MAX_ATTEMPTS}]')
        att += 1
        sleep(15)


def get_posts(soup):
    return [
        div.a.get('href') for div in soup.findAll('div', {'class': 'gallery'})
        if 'english' in div.text.lower()
    ]


def get_torrent_name(file):
    try:
        out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
        torrent_name = re.search(r' 1\|\.\/([^/]*)', out).group(1)
        return torrent_name
    except Exception:
        return ''


def load_config():
    with open(CONFIG, 'r') as f:
        config = json.load(f)
    return config['user-agent'], config['cookie']


def main(urls):
    s = requests.Session()
    user_agent, cookie = load_config()
    s.headers.update({'user-agent': user_agent})
    cookies = [
        {'name': x.strip(), 'value': y.strip()} for x, y in
        [i.split('=') for i in cookie.split(';')]
    ]
    for cookie in cookies:
        s.cookies.set(cookie['name'], cookie['value'], domain=DOMAIN)

    if not os.path.exists(DL_DIR):
        os.mkdir(DL_DIR)

    for url in urls:
        open(HIST, 'a').write(url + '\n')

        try:
            if '?q=' in url:
                r = re.compile(r'\?q=([^&]*)')
            else:
                r = re.compile(r'\.net/\w*/([^/\?$]*)')
            tag = r.search(url.strip()).group(1)
            dl_dir = os.path.join(opts.dl_dir, tag)
            if not os.path.exists(dl_dir):
                os.mkdir(dl_dir)
        except AttributeError:
            dl_dir = opts.dl_dir

        notify(f'{url}\n{dl_dir}')

        if 'page=' in url:
            url = re.sub(r'([\?&]page=)\d*', r'\1{}', url)
        elif '?' in url:
            url += '&page={}'
        else:
            url += '?page={}'

        soup = get_soup(s, url.format(1))
        posts = get_posts(soup)
        last_page = soup.find('a', {'class': 'last'})
        if last_page:
            last_page = int(last_page.get('href').split('=')[-1])
            for page in range(2, last_page + 1):
                print(f'Scraping page {page}...\r', end='')
                soup = get_soup(s, url.format(page))
                posts += get_posts(soup)

        if not posts:
            print('nothing found')
            continue

        for i, post in enumerate(posts, start=1):
            url = f'https://{DOMAIN}{post}download'
            print(f'[{i}/{len(posts)}] {url}')
            fname = post.split('/')[-2] + '.torrent'
            torrent = download(s, url, dl_dir, fname)
            _dir = os.path.join(dl_dir, get_torrent_name(torrent))
            if os.path.exists(_dir) and not opts.overwrite:
                os.remove(torrent)
                continue

            try:
                with open(torrent, 'rb') as fp:
                    data = fp.read()
            except Exception as err:
                print(f'Error reading torrent\n{err}')
                continue

            aria2.aria2.addTorrent(xmlrpc.client.Binary(data), [], {
                'rpc-save-upload-metadata': 'false',
                'force-save': 'false',
                'dir': dl_dir
            })


if __name__ == '__main__':
    opts, args = parse_arguments()

    if opts.input_file:
        with open(opts.input_file, 'r') as f:
            urls = [i.strip() for i in f.readlines() if DOMAIN in i]
    else:
        urls = [i.strip() for i in args if DOMAIN in i]

    aria2 = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')
    main(urls)
