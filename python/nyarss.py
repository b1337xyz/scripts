#!/usr/bin/env python3
import os
import sys
import json
import logging
from time import sleep
from urllib.request import Request, urlopen
from shutil import copy
from argparse import ArgumentParser
import xml.etree.ElementTree as ET

DEFAULT_DL_DIR = os.path.expanduser('~/Downloads')
CONFIG = os.path.expanduser('~/.config/nyarss.json')
HOST = 'http://localhost:6800/jsonrpc'
INTERVAL = 60 * 30
LOCK = '/tmp/.nyarss'


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
        'seed-ratio': 1.1,
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
    if not (url.startswith('https://nyaa') and 'page=rss' in url):
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

    links = config[key]['links']
    for title, uri in rss_links:
        if uri not in links:
            logging.info(f'{title} NEW!')
            links.append(uri)
            if download:
                add_uri(uri, dl_dir)

    config[key]['links'][-100::]
    save_config(config)
    logging.info(f'{key} updated')


def update_all(download=True):
    for v in load_config().values():
        update(v['url'], download)


def monitor():
    if os.path.exists(LOCK):
        logging.error(f'file {LOCK} exists, already running?')
        sys.exit(1)

    open(LOCK, 'w').close()
    try:
        while True:
            update_all()
            sleep(INTERVAL)
    except KeyboardInterrupt:
        pass
    finally:
        os.remove(LOCK)


def select(keys):
    while len(keys) > 0:
        print('Ctrl+c to quit')
        for i, k in enumerate(keys):
            print(f'{i}: {k}')

        if len(keys) == 1:
            return keys[0]

        try:
            n = 0 if len(keys) == 1 else int(input(': '))
            return keys[n]
        except KeyboardInterrupt:
            sys.exit(0)
        except Exception as err:
            print(err)


def delete():
    config = load_config()
    k = select(list(config))
    del config[k]
    save_config(config, False)


def show():
    config = load_config()
    for k in config:
        config[k]['links'] = '[ ... ]'
    print(json.dumps(config, indent=2))


def parse_aguments():
    parser = ArgumentParser()
    parser.add_argument('-d', '--dir', type=str, default=DEFAULT_DL_DIR,
                        help='where to download files (default: %(default)s)')
    parser.add_argument('-f', '--file', type=str,
                        help='add rss feeds from file')
    parser.add_argument('--download', action='store_true',
                        help='add and download')
    parser.add_argument('--delete', action='store_true',
                        help='delete entry')
    parser.add_argument('--show', action='store_true',
                        help='show entries')
    parser.add_argument('--update', action='store_true',
                        help='update all entries')
    parser.add_argument('-q', '--quiet', action='store_true', help='be quiet')
    parser.add_argument('uri', type=str, nargs='?', help='<RSS URI>')
    return parser.parse_args()


def setup_logging(quiet=False):
    logging.basicConfig(
            level=logging.INFO if not quiet else logging.CRITICAL,
            handlers=[logging.StreamHandler(sys.stdout)],
            format='%(asctime)s:%(levelname)s: %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S')


def main():
    args = parse_aguments()
    assert os.path.isdir(args.dir)
    dl_dir = os.path.realpath(args.dir)
    setup_logging(args.quiet)
    if args.delete:
        delete()
    elif args.show:
        show()
    elif args.update:
        update_all(download=False)
    elif args.uri:
        update(url=args.uri, download=args.download, dl_dir=dl_dir)
    elif args.file:
        with open(args.file, 'r') as f:
            for line in f:
                update(url=line, download=args.download, dl_dir=dl_dir)
    else:
        monitor()  # TODO: fork this (daemon)?


if __name__ == '__main__':
    main()
