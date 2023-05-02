#!/usr/bin/env python3
from html import unescape
from random import random
from sys import argv
from time import sleep
import logging
import os
import re
import requests
import subprocess as sp

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'  # noqa: E501
HOME = os.getenv('HOME')
CACHE_DIR = os.getenv('XDG_CACHE_HOME', os.path.join(HOME, '.cache'))
LOG = os.path.join(CACHE_DIR, 'ehentai.log')
DL_DIR = os.path.join(HOME, 'Downloads/e_hentai')
MAX_ATTEMPS = 5


logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='a',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%d-%m-%Y %H:%M:%S',
)


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


def download(url: str, dl_dir: str) -> int:
    p = sp.run(['aria2c', url, '-q', '--dir', dl_dir,
                '--always-resume=false',
                '--max-resume-failure-tries=0',
                '--force-save=false',
                '--auto-file-renaming=false'])
    return p.returncode


def random_sleep():
    sleep(random() * .3)


def get_galleries(s, url):
    s.headers.update({'user-agent': UA})
    r = s.get(url)
    curr_page = page_regex.search(url)
    curr_page = 1 if not curr_page else int(curr_page.group(1))
    try:
        max_page = max([int(i) for i in page_regex.findall(r.text)])
    except ValueError:
        max_page = 1

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
            r = s.get(url)
            random_sleep()
    return galleries


def main(url):
    assert 'e-hentai.org' in url
    sp.run(['notify-send', 'E-hentai downloader started', url])
    logging.info(f'{url = }')

    s = requests.Session()
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
        try:
            r = s.get(url)
        except Exception as err:
            logging.error(f'error requesting: {url}, {r.status_code}, {err}')
            continue

        try:
            url = re.search(r'https://e-hentai\.org/s/[^/]*/\d*-1', r.text)
            url = url.group()
        except AttributeError:
            logging.error(f'nothing found: {url}')
            continue

        try:
            title = title_regex.search(r.text).group(1)
        except AttributeError:
            title = None

        if not title:
            try:
                title = title_regex_fallback.search(r.text).group(1)
                title = ''.join(title.split('-')[:-1])
            except AttributeError:
                title = gid
        title = clean_filename(unescape(title))
        logging.info(f'gallery {c} of {total}: {title} {url}')

        try:
            artist = artist_regex.search(r.text).group(1)
            dl_dir = os.path.join(DL_DIR, f'{artist}/{title}')
        except AttributeError:
            dl_dir = os.path.join(DL_DIR, title)

        if skip_regex and skip_regex.search(title):
            logging.info(f'skipping: {title}')
            continue

        curr_page = 0
        next_page = curr_page + 1
        att = 0
        while next_page > curr_page:
            att += 1
            if att > MAX_ATTEMPS:
                break

            r = s.get(url)
            random_sleep()

            try:
                img = img_regex.search(r.text).group(1)
            except AttributeError:
                logging.error(f'image not found, {url}, attempt: {att} of {MAX_ATTEMPS}')  # noqa: E501
                continue

            if '/509.gif' in img:
                logging.warning(f'509 ERROR, {url} - {img}')
                break

            exit_code = download(img, dl_dir)
            # 13 - If file already existed
            if exit_code not in [0, 13] and att < MAX_ATTEMPS:
                logging.error(f'aria2c error: {exit_code}, {url}, attempt: {att} of {MAX_ATTEMPS}')  # noqa: E501
                continue

            att = 0
            curr_page = int(url.split('-')[-1])
            url = next_regex.search(r.text).group(1)
            next_page = int(url.split('-')[-1])


if __name__ == '__main__':
    try:
        main(argv[1])
    except Exception as err:
        logging.error(f'finished with errors, {err}')
