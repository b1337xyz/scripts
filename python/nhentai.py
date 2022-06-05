#!/usr/bin/env python3
import os
import re
import json
import requests
import subprocess as sp
from bs4 import BeautifulSoup as BS
from optparse import OptionParser

# MAKE SURE YOU USE THE SAME IP AND USERAGENT AS WHEN YOU GOT YOUR COOKIE!
HOME = os.getenv('HOME')
CONFIG = os.path.join(HOME, '.nhentai.json')


def parse_arguments():
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option(
        '-d', '--dir', dest='dl_dir', default='nhentai', metavar='DIR',
        help='download directory'
    )
    parser.add_option(
        '-c', '--cookie', dest='cookie', metavar="STR",
        help="csrftoken=TOKEN; sessionid=ID; cf_clearance=CLOUDFLARE"
    )
    parser.add_option(
        '-i', '--input-file', dest='input_file', metavar='FILE',
        action='store', help='Download URLs found in FILE'
    )
    parser.add_option('-u', '--user-agent', dest='user_agent', metavar="STR")
    return parser.parse_args()


def get_soup(url):
    r = requests.get(
        url,
        cookies={'required_cookie': COOKIE},
        headers={'User-Agent': UA}
    )
    return BS(r.text, 'html.parser')


def download(url, dl_dir, fname):
    file = os.path.join(dl_dir, fname)
    if not os.path.exists(file):
        try:
            r = requests.get(
                url, stream=True,
                cookies={'required_cookie': COOKIE},
                headers={'User-Agent': UA}
            )
            with open(file, 'wb') as fp:
                fp.write(r.content)
        except Exception as err:
            print(f'Failed to download torrent "{url}"\nError: {err}')

    if sp.run([
        'aria2c', '--dir', dl_dir,
        '--log-level=error', '--console-log-level=error',
        '--bt-stop-timeout=500', '--seed-time=0', file
    ]).returncode == 0:
        os.remove(file)


def main(URL):
    if 'page=' in URL:
        URL = re.sub(r'([\?&]page=)\d*', r'\1{}', URL)
    elif '?' in URL:
        URL += '&page={}'
    else:
        URL += '?page={}'

    dl_dir = os.path.realpath(opts.dl_dir)
    if not os.path.exists(dl_dir):
        os.mkdir(dl_dir)
    assert os.path.isdir(dl_dir), f'"{dl_dir}" not a directory'

    try:
        tag = URL.split('?')[0].split('/')[4]
        if tag:
            dl_dir = os.path.join(dl_dir, tag)
            if not os.path.exists(dl_dir):
                os.mkdir(dl_dir)
    except AttributeError:
        pass

    page = 1
    posts = list()
    while True:
        soup = get_soup(URL.format(page))
        gallery = soup.findAll('div', {'class': 'gallery'})
        if not gallery:
            break
        for div in gallery:
            a = div.a.get('href')
            title = div.text.strip()
            if not 'english' in title.lower():
                continue
            posts.append(a)
        page += 1

    for i, post in enumerate(posts, start=1):
        url = f'https://nhentai.net{post}/download'
        print(f'[{i}/{len(posts)}] {url}')
        fname = post.split('/')[-1] + '.torrent'
        download(url, dl_dir, fname)


if __name__ == '__main__':
    args, opts = parse_arguments()
    try:
        with open(CONFIG , 'r') as fp:
            config = json.load(fp)
        UA = config['user-agent']
        COOKIE = config['cookie']
    except FileNotFoundError:
        config = dict()
    try:
        COOKIE = opts.cookie if opts.cookie else config['cookie']
        UA = opts.user_agent if opts.user_agent else config['user-agent']
    except KeyError:
        print("Cookie or User-Agent not defined")
        parser.print_help()
        exit(1)

    if opts.cookie or opts.user_agent:
        with open(CONFIG, 'w') as fp:
            json.dump(config, fp)

    if len(args) == 0 and not opts.input_file:
        parser.error('<url> not provided')

    if opts.input_file:
        with open(opts.input_file, 'r') as fp:
            args = [i.strip() for i in fp.readlines() if 'nhentai.net' in i]
    for i in args:
        if not re.match(r'^https://nhentai', i):
            parser.error('Invalid URL')
        main(i)
