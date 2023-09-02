#!/usr/bin/env python3
import os
import re
import sys
import json
import logging
import atexit
import signal
from time import sleep
from urllib.request import Request, urlopen
from shutil import copy
from argparse import ArgumentParser
import xml.etree.ElementTree as ET

DEFAULT_DL_DIR = os.path.expanduser('~/Downloads')
CONFIG = os.path.expanduser('~/.config/nyarss.json')
LOG = os.path.expanduser('~/.cache/nyarss.log')
HOST = 'http://127.0.0.1:6800/jsonrpc'
INTERVAL = 60 * 30
LOCK = '/tmp/.nyarss'
RE_NYAA = re.compile(r'^https://(?:sukebei\.)?nyaa.*[\?&]page=rss.*')


def load_config(file=CONFIG):
    try:
        with open(file, 'r') as f:
            return json.load(f)
    except json.decoder.JSONDecodeError:
        return load_config(f'{file}.bak')
    except FileNotFoundError:
        return dict()


def save_config(config: str, update: bool = True):
    old = None
    if update:
        old = load_config()  # "safe"
        old.update(config)

    with open(CONFIG, 'w') as f:
        json.dump(config if old is None else old, f)
    copy(CONFIG, f'{CONFIG}.bak')


def parse_feed(url: str):
    print(f'Requesting {url}')
    req = Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urlopen(req) as res:
        xml = res.read().decode()

    root = ET.fromstring(xml)
    feed_title = root.find('channel').find('title').text
    links = list()
    for item in root.find('channel').findall('item'):
        title = item.find('title').text
        link = item.find('link').text
        links.append((title, link))
    return feed_title, links


def add_uri(uri: str, dl_dir: str):
    options = {
        'dir': dl_dir,
        'force-save': 'false',
        'bt-save-metadata': 'false',
        'check-integrity': 'true'
    }
    jsonreq = json.dumps({
        'jsonrpc': '2.0',
        'id': 'nyarss',
        'method': 'aria2.addUri',
        'params': [[uri], options]
    }).encode('utf-8')
    req = Request(HOST)
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    urlopen(req, jsonreq)


def update(url: str, download: bool = False, dl_dir: str = None):
    if not RE_NYAA.match(url):
        logging.error(f'Invalid url: "{url}"')
        return

    config = load_config()
    key, rss_links = parse_feed(url)
    if key not in config:
        config[key] = {'url': url, 'links': []}

    if dl_dir is None:
        dl_dir = config[key].get('dir', DEFAULT_DL_DIR)
    else:
        config[key]['dir'] = dl_dir

    if not os.path.isdir(dl_dir):
        del config[key]
        save_config(config, update=False)
        return

    links = config[key]['links']
    for title, uri in rss_links:
        if uri not in links:
            logging.info(f'{title} NEW!')
            links.append(uri)
            if download:
                add_uri(uri, dl_dir)

    config[key]['links'][-100::]
    save_config(config)
    # logging.info(f'{key} updated')


def update_all(download=True):
    for v in load_config().values():
        update(v['url'], download)


def monitor(seconds=INTERVAL):
    assert seconds > 300

    if os.path.exists(LOCK):
        logging.error(f'lock file {LOCK} exists, already running?')
        sys.exit(1)

    @atexit.register
    def cleanup(code=None, frame=None):
        """ Cleanup at exit and by SIGTERM """
        if os.path.isfile(LOCK):
            os.remove(LOCK)

        if code is not None:  # if SIGTERM
            sys.exit(0)       # will run again by atexit

    open(LOCK, 'w').close()
    signal.signal(signal.SIGTERM, cleanup)
    while True:
        update_all()
        sleep(seconds)


def select():
    keys = list(load_config().keys())
    len_ = len(keys)
    while len_ > 0:
        print('Ctrl+c to quit')
        for i, k in enumerate(keys):
            print(f'\033[1;34m{i}\033[m) {k}')

        if len_ == 1:
            return keys[0]

        try:
            n = int(input(': '))
            return keys[n]
        except KeyboardInterrupt:
            sys.exit(0)
        except Exception as err:
            print(err)


def chdir(new_dir):
    assert os.path.isdir(new_dir)
    k = select()
    config = load_config()
    config[k]['dir'] = os.path.realpath(new_dir)
    save_config(config)


def delete():
    k = select()
    config = load_config()
    del config[k]
    save_config(config, update=False)


def show():
    config = load_config()
    for k in config:
        config[k]['links'] = '[ ... ]'
    print(json.dumps(config, indent=2))


def parse_aguments():
    global parser
    parser = ArgumentParser()
    parser.add_argument('-q', '--quiet', action='store_true', help='be quiet')
    parser.add_argument('-d', '--dir', type=str, default=DEFAULT_DL_DIR,
                        help='where to download files (default: %(default)s)')
    parser.add_argument('-f', '--file', type=str,
                        help='add rss feeds from file')
    parser.add_argument('-s', '--seconds', default=INTERVAL, type=int,
                        metavar='N', help='default: %(default)s')
    parser.add_argument('--loop', action='store_true',
                        help='update and download every N seconds')
    parser.add_argument('--download', action='store_true',
                        help='add and download')
    parser.add_argument('-c', '--change-dir', type=str)
    parser.add_argument('uri', type=str, nargs='?', help='<RSS URI>')
    return parser.parse_args()


def setup_logging(quiet=False):
    logging.basicConfig(
            level=logging.CRITICAL if quiet else logging.INFO,
            handlers=[
                logging.FileHandler(LOG, mode='a'),
                logging.StreamHandler(sys.stdout)
            ],
            format='%(asctime)s:%(levelname)s: %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S')


def main():
    args = parse_aguments()
    argv = sys.argv[1:]
    assert os.path.isdir(args.dir)
    dl_dir = os.path.realpath(args.dir)

    setup_logging(args.quiet)

    if 'show' in argv:
        show()
    elif 'delete' in argv:
        delete()
    elif 'update' in argv:
        update_all(download=False)
    elif args.uri:
        update(url=args.uri, download=args.download, dl_dir=dl_dir)
    elif args.file:
        with open(args.file, 'r') as f:
            for line in f:
                update(url=line, download=args.download, dl_dir=dl_dir)
    elif args.loop:
        monitor(args.seconds)  # TODO: fork this (daemon)?
    elif args.change_dir:
        chdir(args.change_dir)
    else:
        print('Nothing to do')
        parser.print_help()


if __name__ == '__main__':
    main()
