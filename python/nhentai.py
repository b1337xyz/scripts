#!/usr/bin/env python3
import os
import re
import json
import bencode
import requests
# import subprocess as sp
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
    parser.error('URL not provided')

URL = args[0].split('?')[0]
if not re.match(r'^https://nhentai', URL):
    parser.error('Invalid URL')
DL_DIR = os.path.realpath(opts.dl_dir)
if not os.path.exists(DL_DIR):
    os.mkdir(DL_DIR)
assert os.path.isdir(DL_DIR), '"{}" not a directory'.format(DL_DIR)

# cmd = sp.run(['which', 'aria2c'], stdout=sp.DEVNULL, stderr=sp.DEVNULL)
# aria2_is_installed = cmd.returncode == 0


def get_html(url):
    r = requests.get(
        url,
        cookies={'required_cookie': COOKIE},
        headers={'User-Agent': UA}
    )
    return r.text


def download(url, fname):
    file = os.path.join(DL_DIR, fname)
    r = requests.get(
        url,
        cookies={'required_cookie': COOKIE},
        headers={'User-Agent': UA},
        stream=True
    )
    with open(file, 'wb') as fp:
        fp.write(r.content)


def rename(fname):
    target = os.path.join(DL_DIR, fname)
    # out = sp.run(['aria2c', '-S', target], stdout=sp.PIPE).stdout.decode()
    # torrent_name = re.search(r' 1\|\./([^/]*)', out)
    with open(target, 'rb') as fp:
        torrent_name = bencode.bdecode(fp.read())['info']['name']
    # if not 'english' in torrent_name.lower():
    #     os.remove(target)
    #     return
    # torrent = os.path.join(DL_DIR, torrent_name.group(1) + '.torrent')
    torrent = os.path.join(DL_DIR, torrent_name + '.torrent')

    if not os.path.exists(torrent):
        os.rename(target, torrent)
    return torrent_name


def main():
    page = 1
    posts = []
    while True:
        url = '{}?page={}'.format(URL, page)
        html = get_html(url)
        lst = re.findall(r'href="([^""]*/g/\d*)', html)
        if not lst:
            break
        print('Scraping page {} ...\r'.format(page), end='')
        posts += lst
        page += 1

    for i, v in enumerate(posts, start=1):
        url = 'https://nhentai.net{}/download'.format(v)
        fname = '{}.torrent'.format(v.split('/')[-1])
        download(url, fname)
        # if aria2_is_installed:
        torrent_name = rename(fname)
        print('{:<4} of {:<4} {}'.format(i, len(posts), torrent_name))


if __name__ == '__main__':
    main()
