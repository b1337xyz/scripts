#!/usr/bin/env python3
from html import unescape
from random import random
from sys import argv
from time import sleep
from http.cookiejar import MozillaCookieJar
from pathlib import Path
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import os
import re
import requests

requests.packages.urllib3.disable_warnings()

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'  # noqa: E501
HOME = os.getenv('HOME')
CACHE_DIR = os.getenv('XDG_CACHE_HOME', os.path.join(HOME, '.cache'))
DL_DIR = os.path.join(HOME, 'Downloads/e_hentai')
COOKIE_FILE = os.path.join(CACHE_DIR, 'e-hentai.cookie')
HIST = os.path.join(CACHE_DIR, 'ehentai.history')
MAX_ATTEMPS = 5


gallery_regex = re.compile(r'href=\"https://e-hentai\.org/g/(\d*/[^/]*)/')
page_regex = re.compile(r'[\?\&]page=(\d+)')
# img_regex = re.compile(r'https://\w*\.\w*\.hath\.network(?:\:\d+)?/\w/[^\"]*\.(?:jpe?g|png|gif)')  # noqa: E501
img_regex = re.compile(r'<img id=\"img\" src=\"([^\"]*)')
title_regex = re.compile(r'<h1 id="gn">([^<]*)</h1>')
title_regex_fallback = re.compile(r'<title>([^<]*)</title>')
next_regex = re.compile(r'<a id="next"[^>]*href=\"([^\"]*-\d+)\"')
artist_regex = re.compile(r'<a id="ta_artist:([^\"]*)')
skip_regex = re.compile(r'twitter|collection|gallery|hd pack', re.IGNORECASE)  # noqa: E501
skip_regex = None


def clean_filename(s: str) -> str:
    keep = ' .!_[]()'
    s = ''.join(c for c in s if c.isalnum() or c in keep)
    return re.sub(r'\s{2,}', ' ', s).strip()


def mkdir(path):
    Path(path).mkdir(exist_ok=True, parents=True)


def get(s, url, stream=False):
    sleep(random() * .8)
    return s.get(url, stream=stream, verify=False)


def download(s, url, filepath):
    if os.path.exists(filepath):
        print(filepath)
        return

    tempfile = f'{filepath}.temp'
    r = get(s, url, stream=True)
    with open(tempfile, 'wb') as f:
        f.write(r.content)

    os.rename(tempfile, filepath)
    print(f'\033[1;32m{filepath}\033[m')


def get_galleries(s, url):
    r = get(s, url)
    curr_page = page_regex.search(url)
    curr_page = 1 if not curr_page else int(curr_page.group(1))
    max_page = max(map(int, page_regex.findall(r.text)), default=1)
    galleries = list()
    for page in range(curr_page, max_page + 1):
        for link in gallery_regex.findall(r.text):
            gid, token = link.split('/')
            galleries.append([gid, token])

        if max_page > curr_page:
            if page_regex.search(url):
                url = re.sub(r'([\?\&]page)=(\d+)', r'\1={}'.format(page), url)
            else:
                url += f'&page={page}' if '?' in url else f'?page={page}'
            r = get(s, url)
    return galleries


def create_session():
    s = requests.Session()

    # https://stackoverflow.com/questions/23013220/max-retries-exceeded-with-url-in-requests
    retry = Retry(connect=3, backoff_factor=0.5)
    adapter = HTTPAdapter(max_retries=retry)
    s.mount('http://', adapter)
    s.mount('https://', adapter)

    s.headers.update({'user-agent': UA})
    cj = MozillaCookieJar(COOKIE_FILE)
    cj.load(ignore_discard=True, ignore_expires=True)
    s.cookies = cj
    return s


def main(url):
    assert 'e-hentai.org' in url
    open(HIST, 'a').write(f'{url}\n')

    s = create_session()

    if re.search(r'\.org/g/\d+', url):
        gid, token = re.search(r'/g/(\d+)/([^/]*)', url).group(1, 2)
        galleries = [(gid, token)]
    else:
        galleries = get_galleries(s, url)

    c = 0
    total = len(galleries)
    for gid, token in galleries:
        c += 1
        url = f'https://e-hentai.org/g/{gid}/{token}/'
        r = get(s, url)

        try:
            url = re.search(r'https://e-hentai\.org/s/[^/]*/\d*-1', r.text)
            url = url.group()
        except AttributeError:
            print(f'nothing found, {url}')
            continue

        if (title := title_regex.search(r.text)):
            title = title.group(1)
        elif (title := title_regex_fallback.search(r.text)):
            title = ''.join(title.group(1).split('-')[:-1])
        else:
            title = gid

        title = clean_filename(unescape(title))
        print(f'gallery {c} of {total}: {title} {url}')

        try:
            artist = artist_regex.search(r.text).group(1)
            dl_dir = os.path.join(DL_DIR, f'{artist}/{title}')
        except AttributeError:
            dl_dir = os.path.join(DL_DIR, title)

        if skip_regex and skip_regex.search(title):
            print(f'skipping: {title}')
            continue

        mkdir(dl_dir)

        curr_page = 0
        next_page = curr_page + 1
        while next_page > curr_page:
            att = 0
            while att < MAX_ATTEMPS:
                att += 1
                r = get(s, url)
                try:
                    img = img_regex.search(r.text).group(1)
                except AttributeError:
                    print(f'image not found, {url}, attempt: {att} of {MAX_ATTEMPS}')  # noqa: E501
                    continue

                if '/509.gif' in img:
                    print(f'509 IMAGE, {url} - {img}')
                    exit(1)

                filename = img.split('/')[-1].split('?')[0]
                filename, ext = os.path.splitext(filename)
                filename = '{}_page-{}{}'.format(filename, curr_page + 1, ext)
                filepath = os.path.join(dl_dir, filename)
                try:
                    download(s, img, filepath)
                    break
                except Exception:
                    print(f'download failed, {url}, attempt: {att} of {MAX_ATTEMPS}')  # noqa: E501

            curr_page = int(url.split('-')[-1])
            url = next_regex.search(r.text).group(1)
            next_page = int(url.split('-')[-1])


if __name__ == '__main__':
    try:
        main(argv[1])
    except KeyboardInterrupt:
        pass
    except Exception as err:
        print(f'finished with errors, {err}')
