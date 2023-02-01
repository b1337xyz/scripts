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
DL_DIR = os.path.join(HOME, 'Downloads/e_hentai')
LOG = os.path.join(HOME, '.cache/ehentai.log')

logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='a',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%d-%m-%Y %H:%M:%S',
)


def clean_filename(s: str) -> str:
    keep = [' ', '.', '!', '_', '[', ']', '(', ')']
    s = ''.join(c for c in s if c.isalnum() or c in keep)
    return re.sub(r'\s{2,}', ' ', s).strip()


gallery_regex = re.compile(r'href=\"https://e-hentai\.org/g/(\d*/[^/]*)/')
page_regex = re.compile(r'[\?\&]page=(\d+)')
# img_regex = re.compile(r'https://\w*\.\w*\.hath\.network(?:\:\d+)?/\w/[^\"]*\.(?:jpe?g|png|gif)')  # noqa: E501
img_regex = re.compile(r'<img id=\"img\" src=\"([^\"]*)')
title_regex = re.compile(r'<h1 id="gn">([^<]*)</h1>')
title_regex_fallback = re.compile(r'<title>([^<]*)</title>')
next_regex = re.compile(r'<a id="next"[^>]*href=\"([^\"]*-\d+)\"')
artist_regex = re.compile(r'<a id="ta_artist:([^\"]*)')
skip_regex = re.compile(r'twitter|patreon|fanbox|pixiv|collection|gallery|hd pack', re.IGNORECASE)  # noqa: E501


url = argv[1]
assert 'e-hentai.org' in url
logging.info(f'{url = }')
s = requests.Session()
s.headers.update({'user-agent': UA})
r = s.get(url)
curr_page = page_regex.search(url)
curr_page = 1 if not curr_page else int(curr_page.group(1))
try:
    max_page = max([int(i) for i in page_regex.findall(r.text)])
except ValueError:
    max_page = 1

sp.run(['notify-send', 'E-hentai downloader started', url])

gallery = list()
for page in range(curr_page, max_page + 1):
    for link in gallery_regex.findall(r.text):
        gid, token = link.split('/')
        gallery.append([gid, token])
    if max_page > curr_page:
        if page_regex.search(url):
            url = re.sub(r'([\?\&]page)=(\d+)', r'\1={}'.format(page), url)
        else:
            url += f'&page={page}' if '?' in url else f'&page={page}'
        r = s.get(url)

for gid, token in gallery:
    url = f'https://e-hentai.org/g/{gid}/{token}/'
    r = s.get(url)

    try:
        url = re.search(r'https://e-hentai\.org/s/[^/]*/\d*-1', r.text).group()
    except Exception:
        logging.error(f'nothing found: {url = }')
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
    try:
        artist = artist_regex.search(r.text).group(1)
        dl_dir = os.path.join(DL_DIR, f'{artist}/{title}')
    except AttributeError:
        dl_dir = os.path.join(DL_DIR, title)

    if skip_regex.search(title):
        logging.info(f'Skipping: {title}')
        continue

    curr_page = 0
    next_page = curr_page + 1
    output = '/tmp/.ehentai'
    open(output, 'w').close()
    while next_page > curr_page:
        r = s.get(url)
        img = img_regex.search(r.text).group(1)
        print(img)
        if '/509.gif' in img:
            logging.warning(f'509 ERROR, {url} - {img}')
            break

        with open(output, 'a') as fp:
            fp.write(img + '\n')
        # p = sp.run([
        #     'aria2c', '--dir', dl_dir, '-U', UA, img
        # ], stdout=sp.DEVNULL, stderr=sp.DEVNULL)
        # if p.returncode != 0:
        #     logging.error(f'Download finished with errors: {img = }, {argv[1] = }')  # noqa: E501

        curr_page = int(url.split('-')[-1])
        url = next_regex.search(r.text).group(1)
        next_page = int(url.split('-')[-1])
        sleep(random() * .5)

    p = sp.run([
        'aria2c', '-x', '6', '-s', '6', '--dir', dl_dir, '-U', UA,
        '--input-file', output
    ])
    if p.returncode != 0:
        logging.error(f'Download finished with errors: {url}, {argv[1] = }')
