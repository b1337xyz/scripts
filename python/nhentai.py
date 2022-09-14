#!/usr/bin/env python3
from bs4 import BeautifulSoup as BS
from optparse import OptionParser
import json
import os
import re
import requests
import subprocess as sp

# MAKE SURE YOU USE THE SAME IP AND USERAGENT AS WHEN YOU GOT YOUR COOKIE!
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.nhentai_history')
CONFIG = os.path.join(HOME, '.nhentai.json')
DL_DIR = os.path.join(HOME, 'Downloads/nhentai')
DOMAIN = 'nhentai.net'


def parse_arguments():
    global parser
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option(
        '-d', '--dir', dest='dl_dir', default=DL_DIR, metavar='DIR',
        help='download directory'
    )
    parser.add_option(
        '-i', '--input-file', dest='input_file', metavar='FILE',
        action='store', help='Download URLs found in FILE'
    )
    parser.add_option(
        '-c', '--cookie', dest='cookie', metavar="STR",
        help="csrftoken=TOKEN; sessionid=ID; cf_clearance=CLOUDFLARE"
    )
    parser.add_option('-u', '--user-agent', dest='user_agent', metavar="STR")
    parser.add_option('-a', '--artist', dest='artist', default=None)
    opts, args = parser.parse_args()
    if len(args) == 0 and not opts.input_file:
        parser.error('<url> not provided')
    if not os.path.exists(opts.dl_dir): os.mkdir(opts.dl_dir)
    assert os.path.isdir(opts.dl_dir), f'"{opts.dl_dir}" not a directory'
    return (opts, args)


def load_config(cookie=None, agent=None):
    try:
        with open(CONFIG , 'r') as fp:
            config = json.load(fp)
    except FileNotFoundError:
        config = dict()
    if cookie:
        config['cookie'] = cookie
    if agent:
        config['user-agent'] = agent
    if cookie or agent:
        with open(CONFIG, 'w') as fp:
            json.dump(config, fp, indent=2)
    return config


def download(session, url, dl_dir, fname):
    file = os.path.join(dl_dir, fname)
    if not os.path.exists(file):
        try:
            r = session.get(url, stream=True)
            with open(file, 'wb') as fp:
                fp.write(r.raw.read())
        except Exception as err:
            print(f'Failed to download torrent "{url}"\nError: {err}')

    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    torrent_name = re.search(r'[ \t]*\d\|\./([^/]*)', out)
    if torrent_name:
        torrent = os.path.join(dl_dir, torrent_name.group(1))
        if os.path.exists(torrent):
            os.remove(file)
    return file


def get_soup(session, url):
    content = session.get(url).content
    return BS(content, 'html.parser')


def main(urls):
    s = requests.Session()
    s.headers.update({'user-agent': UA})
    cookies = [
        {'name': x.strip(), 'value': y.strip()} for x, y in
        [i.split('=') for i in COOKIE.split(';')]
    ]
    for cookie in cookies:
        s.cookies.set(
            cookie['name'],
            cookie['value'],
            domain = DOMAIN
        )

    for url in urls:
        with open(HIST, 'a') as fp:
            fp.write(url + '\n')

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

        if 'page=' in url:
            url = re.sub(r'([\?&]page=)\d*', r'\1{}', url)
        elif '?' in url:
            url += '&page={}'
        else:
            url += '?page={}'

        soup = get_soup(s, url.format(1))
        gallery = soup.findAll('div', {'class': 'gallery'})
        posts = list()
        for div in gallery:
            a = div.a.get('href')
            if not 'english' in div.text.lower():
                continue
            posts.append(a)
        last_page = soup.find('a', {'class': 'last'})
        if last_page:
            last_page = int(last_page.get('href').split('=')[-1])
            posts = list()
            for page in range(2, last_page + 1):
                print(f'Scraping page {page}...\r', end='')
                soup = get_soup(s, url.format(page))
                gallery = soup.findAll('div', {'class': 'gallery'})
                for div in gallery:
                    a = div.a.get('href')
                    if not 'english' in div.text.lower():
                        continue
                    posts.append(a)

        if not posts:
            print('nothing found')
            continue

        torrents = list()
        for i, post in enumerate(posts, start=1):
            url = f'https://{DOMAIN}{post}download'
            print(f'[{i}/{len(posts)}] {url}')
            fname = post.split('/')[-2] + '.torrent'
            torrents.append(download(s, url, dl_dir, fname))

        sp.run([
            'aria2c', '--dir', dl_dir,
            '--bt-stop-timeout=500',
            '--seed-time=0'
        ] + torrents)


if __name__ == '__main__':
    opts, args = parse_arguments()
    config = load_config(opts.cookie, opts.user_agent)

    try:
        UA = config['user-agent']
        COOKIE = config['cookie']
    except KeyError:
        print("Cookie or User-Agent not defined")
        parser.print_help()
        exit(1)

    if opts.artist:
        artist = opts.artist.strip().replace(' ', '-')
        args = [f'https://{DOMAIN}/artist/{artist}/']

    if opts.input_file:
        with open(opts.input_file, 'r') as fp:
            urls = [i.strip() for i in fp.readlines() if DOMAIN in i]
    else:
        urls = [i for i in args if DOMAIN in i]

    try:
        main(urls)
    except KeyboardInterrupt:
        pass
    finally:
        print('\nbye')
