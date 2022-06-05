#!/usr/bin/env python3
import os
import re
import json
import requests
import subprocess as sp
from optparse import OptionParser

# MAKE SURE YOU USE THE SAME IP AND USERAGENT AS WHEN YOU GOT YOUR COOKIE!

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
parser.add_option('-u', '--user-agent', dest='user_agent', metavar="STR")
opts, args = parser.parse_args()

HOME = os.getenv('HOME')
CONFIG = os.path.join(HOME, '.nhentai.json')
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

if len(args) == 0:
    parser.error('<url> not provided')

URL = args[0]
if not re.match(r'^https://nhentai', URL):
    parser.error('Invalid URL')
if 'page=' in URL:
    URL = re.sub(r'([\?&]page=)\d*', r'\1{}', URL)
elif '?' in URL:
    URL += '&page={}'
else:
    URL += '?page={}'


DL_DIR = os.path.realpath(opts.dl_dir)
if not os.path.exists(DL_DIR):
    os.mkdir(DL_DIR)
assert os.path.isdir(DL_DIR), f'"{DL_DIR}" not a directory'

try:
    tag = URL.split('?')[0].split('/')[4]
    if tag:
        DL_DIR = os.path.join(DL_DIR, tag)
        if not os.path.exists(DL_DIR):
            os.mkdir(DL_DIR)
except AttributeError:
    pass


def get_html(url):
    r = requests.get(
        url,
        cookies={'required_cookie': COOKIE},
        headers={'User-Agent': UA}
    )
    return r.text


def download(url, fname):
    file = os.path.join(DL_DIR, fname)
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
    mime = sp.run(['file', '-bi', file], stdout=sp.PIPE).stdout.decode()
    if not 'bittorrent' in mime:
        os.remove(file)
        return
    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    try:
        torrent_name = re.search(r' 1\|\./([^/]*)', out).group(1)
    except AttributeError:
        os.remove(file)
        return
    torrent = os.path.join(DL_DIR, torrent_name)
    if os.path.exists(torrent):
        os.remove(file)
        return
    if not 'english' in torrent_name.lower():
        os.remove(file)
        return

    if sp.run([
        'aria2c', '--dir', DL_DIR,
        '--log-level=error', '--console-log-level=error',
        '--bt-stop-timeout=500', '--seed-time=0', file
    ]).returncode == 0:
        os.remove(file)


def main():
    page = 1
    while True:
        url = URL.format(page)
        html = get_html(url)
        posts = re.findall(r'href="([^""]*/g/\d*)', html)
        if not posts:
            break
        for i in posts:
            url = f'https://nhentai.net{i}/download'
            fname = i.split('/')[-1] + '.torrent'
            download(url, fname)


if __name__ == '__main__':
    main()
