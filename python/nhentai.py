#!/usr/bin/env python3
from bs4 import BeautifulSoup as BS
from optparse import OptionParser
from pathlib import Path
import xmlrpc.client
import requests
import re
import os

USER_AGENT = '''
Mozilla...
'''  # noqa: E501

COOKIE = '''
csrftoken=...; sessionid=...; cf_clearance=...
'''  # noqa: E501

HOME = Path(os.getenv('HOME'))
DL_DIR = HOME / 'Downloads/nhentai'

CACHE_DIR = Path(os.getenv('XDG_CACHE_HOME', HOME / '.cache'))
HISTORY = CACHE_DIR / 'nhentai_history'
DOMAIN = 'nhentai.net'
RPC_HOST = 'http://localhost'
RPC_PORT = 6800


def parse_arguments():
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option('-d', '--dir', default=DL_DIR)
    parser.add_option('-i', '--file')
    opts, args = parser.parse_args()
    if not args and not opts.file:
        parser.error('<url> not provided')
    return opts, args


def start_session():
    s = requests.Session()
    s.headers.update({'user-agent': USER_AGENT.strip()})
    for cookie in COOKIE.split(';'):
        name, value = map(str.strip, cookie.split('='))
        s.cookies.set(name, value, domain=DOMAIN)
    return s


def get_soup(url):
    print(f'GET: {url}')
    r = session.get(url)
    return BS(r.text, 'html.parser')


def download(url, file):
    if file.exists():
        with open(file, 'rb') as f:
            data = f.read()
    else:
        r = session.get(url, stream=True)
        data = r.raw.read()
        open(file, 'wb').write(data)

    try:
        aria2.aria2.addTorrent(xmlrpc.client.Binary(data), [], {
            'rpc-save-upload-metadata': 'false', 'force-save': 'false',
            'dir': str(file.parent)
        })
    except Exception:
        pass  # probably a connection error, check the rpc


def get_posts(url, page=1):
    posts = []
    while True:
        soup = get_soup(url.format(page))
        posts += [
            'https://{}{}download'.format(DOMAIN, div.a.get('href'))
            for div in soup.find_all('div', class_='gallery')
            if 'english' in div.text.lower()
        ]
        if soup.find('a', class_='last') is None:
            return posts
        page += 1


def main(urls):
    global session
    session = start_session()
    for url in urls:
        open(HISTORY, 'a').write(f'{url}\n')

        dl_dir = Path(opts.dir)
        try:
            tag = url.split('/')[4].split('?')[0]
            dl_dir /= tag
        except Exception:
            pass
        dl_dir.mkdir(parents=True, exist_ok=True)

        if 'page=' in url:
            url = re.sub(r'([\?&]page=)\d*', r'\1{}', url)
        else:
            url += '&page={}' if '?' in url else '?page={}'

        for url in get_posts(url):
            fname = url.split('/')[-2] + '.torrent'
            file = dl_dir / fname
            download(url, file)


if __name__ == '__main__':
    opts, args = parse_arguments()
    aria2 = xmlrpc.client.ServerProxy(f'{RPC_HOST}:{RPC_PORT}/rpc')

    if opts.file:
        with open(opts.file, 'r') as f:
            urls = [i.strip() for i in f.readlines() if DOMAIN in i]
    else:
        urls = [i.strip() for i in args if DOMAIN in i]

    main(urls)
