#!/usr/bin/env python3
from time import sleep
from optparse import OptionParser
from shutil import which, copy
from pathlib import Path
import subprocess as sp
import json
import requests
import re
import os


UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) QtWebEngine/5.15.7 Chrome/87.0.4280.144 Safari/537.36'  # noqa: E501
ROOT = os.path.dirname(os.path.realpath(__file__))
HOME = os.getenv('HOME', ROOT)
CACHE_DIR = os.getenv('XDG_CACHE_HOME', ROOT)
CACHE = os.path.join(CACHE_DIR, 'imhentai.json')
DL_DIR = os.path.join(HOME, 'Downloads')
RE_GALLERY = re.compile(r'href="/(gallery/\d+/?)"')
SESSIONFILE = os.path.join(CACHE_DIR, 'imhentai.session')

try:
    with open(SESSIONFILE, 'r') as f:
        PHPSESSID = f.readline().strip()
    if not PHPSESSID:
        raise Exception
except Exception:
    print('Access the site, open devtools and go to the Network tab')
    PHPSESSID = input('PHPSESSID: ').strip()
    with open(SESSIONFILE, 'w') as f:
        f.write(PHPSESSID)


def parse_arguments():
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option('-d', '--dir', type='string', default=DL_DIR)
    parser.add_option('-i', '--input-file', type='string', metavar='FILE')
    parser.add_option('--start-page', type='int')
    parser.add_option('--max-page', type='int')
    parser.add_option('--overwrite', action='store_true')
    opts, args = parser.parse_args()
    if len(args) == 0 and not opts.input_file:
        parser.error('<url> not provided')
    if opts.input_file:
        with open(opts.input_file, 'r') as f:
            args += [i.strip() for i in f.readlines() if i]
    return opts, args


def download(url):
    try:
        filename = re.search(r'file=([^&]*)', url).group(1).replace('/', '_')
    except AttributeError:
        filename = ''.join(url.split('/')[-1].split('?')[0])

    filepath = os.path.join(dl_dir, filename)
    if os.path.exists(filepath) and not opts.overwrite:
        print(f'{filepath} already exists.')
        return filename

    if which('aria2c'):
        host = 'http://localhost:6800/jsonrpc'
        data = json.dumps({
            'jsonrpc': '2.0', 'id': '0',
            'method': 'aria2.addUri',
            'params': [[url], {'dir': dl_dir, 'out': filename}]
        })
        try:
            r = requests.post(host, data=data)
            if not r.ok:
                raise ValueError
        except Exception:
            sp.run(['aria2c', '--dir', dl_dir, '--out', filename, url])

    elif which('wget'):
        sp.run(['wget', '-nc', '-O', filepath, url])

    else:
        r = requests.get(url, stream=True)
        with open(filepath, 'wb') as f:
            f.write(r.content)

    return filename


def get_download_url(url, data):
    headers = {
        'authority': 'imhentai.xxx',
        'path': '/inc/dl_new.php',
        'origin': 'https://imhentai.xxx',
        'referer': url,
        'cookie': f'PHPSESSID={PHPSESSID}',
        'user-agent': UA,
        'x-requested-with': 'XMLHttpRequest'
    }
    resp = session.post('https://imhentai.xxx/inc/dl_new.php',
                        headers=headers, data=data).text
    if 'wait' in resp:
        t = int(resp.split(',')[-1]) + 1
        for i in range(t, 0, -1):
            print(f'wait {i:>3}s', end='\r')
            sleep(1)
        return get_download_url(url, data)

    if 'success' in resp:
        return resp.replace('success,', '')


def parse_data(html):
    data = dict()
    for k in ['gallery_id', 'load_id', 'load_dir', 'gallery_title']:
        data[k] = re.search(r'id="{}"[^>]* value=\"([^\"]*)\"'.format(k),
                            html).group(1)
    # print(json.dumps(data, indent=2))
    return data


def download_gallery(url):
    if url in cache:
        filepath = os.path.join(dl_dir, cache[url])
        if os.path.exists(filepath) and not opts.overwrite:
            print(f'{filepath} already exists.')
            return

    html = session.get(url).text
    data = parse_data(html)
    dl_url = get_download_url(url, data)
    if not dl_url:
        print(f"failed to download {url}")
        return

    filename = download(dl_url)
    cache[url] = filename

    if os.path.exists(CACHE):
        copy(CACHE, f'{CACHE}.bak')

    with open(CACHE, 'w') as f:
        json.dump(cache, f)


def download_galleries(url):
    html = session.get(url).text
    try:
        max_page = max(map(int, re.findall(r'\?page=(\d+)', html)))
    except ValueError:
        max_page = 2

    if opts.max_page and opts.max_page < max_page:
        max_page = opts.max_page

    page = re.search(r'page=(\d+)', url)
    start_page = 1 if not page else int(page.group(1))
    start_page = opts.start_page if opts.start_page else start_page

    dups = []
    for page in range(start_page, max_page + 1):
        print(f'Page {page} of {max_page}')
        galleries = RE_GALLERY.findall(html)
        total = len(galleries)
        for i, _id in enumerate(galleries, start=1):
            url = f'https://imhentai.xxx/{_id}'
            print(f'[{i}/{total}] {url}')
            if url not in dups:
                download_gallery(url)
                dups.append(url)

        if page < max_page:
            url = f'https://imhentai.xxx/?page={page + 1}'
            html = session.get(url).text


def load_cache():
    try:
        with open(CACHE, 'r') as f:
            return json.load(f)
    except json.decoder.JSONDecodeError:
        bak = os.path.exists(f'{CACHE}.bak')
        if os.path.exists(bak):
            return load_cache(bak)
    except FileNotFoundError:
        return dict()


def mkdir(path):
    Path(path).mkdir(parents=True, exist_ok=True)


def main():
    global session, cache, opts, dl_dir
    opts, args = parse_arguments()
    session = requests.Session()
    session.headers.update({'user-agent': UA})
    session.cookies.set('PHPSESSID', PHPSESSID, domain='imhentai.xxx')
    cache = load_cache()
    opts.dir = os.path.join(opts.dir, 'imhentai')

    for url in args:
        dl_dir = opts.dir
        for v in ['tag', 'artist', 'parody', 'character']:
            if (r := re.search(r'/{}/([^/]*)'.format(v), url)):
                dl_dir = os.path.join(opts.dir, r.group(1))
                break
        mkdir(dl_dir)

        if '/gallery/' in url:
            download_gallery(url)
        else:
            download_galleries(url)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nbye ^-^')
