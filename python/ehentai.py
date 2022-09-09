#!/usr/bin/env python3
from html import unescape
from random import random
from sys import argv
from time import sleep
import json
import logging
import os
import re
import requests
import subprocess as sp

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'
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


def clean_filename(s: str):
    keep = [' ', '.', '_', '[', ']', '(', ')']
    s = ''.join(c for c in s if c.isalnum() or c in keep)
    return re.sub('\s{2,}', ' ', s).strip()


gallery_regex = re.compile(r'href=\"https://e-hentai\.org/g/(\d*/[^/]*)/')
page_regex    = re.compile(r'[\?\&]page=(\d+)')
# img_regex   = re.compile(r'https://\w*\.\w*\.hath\.network(?:\:\d+)?/\w/[^\"]*\.(?:jpe?g|png|gif)')
img_regex     = re.compile(r'<img id=\"img\" src=\"([^\"]*)')
title_regex   = re.compile(r'<h1 id="gn">([^<]*)</h1>')
next_regex    = re.compile(r'<a id="next"[^>]*href=\"([^\"]*-\d+)\"')
artist_regex  = re.compile(r'<a id="ta_artist:([^\"]*) ')


url = argv[1]
s = requests.Session()
s.headers.update({'user-agent': UA})
r = s.get(url)
curr_page = page_regex.search(url)
curr_page = 1 if not curr_page else curr_page.group(1)
try:
    max_page = sorted([int(i) for i in page_regex.findall(r.text)])[-1]
except IndexError:
    max_page = 1
gallery = list()
for page in range(curr_page, max_page + 1):
    logging.info(url)
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
    logging.info(url)
    r = s.get(url)
    title = title_regex.search(r.text).group(1)
    title = clean_filename(unescape(title))
    try:
        artist = artist_regex.search(r.text).group(1)
        dl_dir = os.path.join(DL_DIR, f'{artist}/{title}')
    except AttributeError:
        dl_dir = os.path.join(DL_DIR, title)

    url = re.search(r'https://e-hentai\.org/s/[^/]*/\d*-1', r.text).group()
    curr_page = 0
    next_page = curr_page + 1
    att = 0
    while next_page > curr_page:
        assert att < 5
        r = s.get(url)
        img = img_regex.search(r.text).group(1)
        p = sp.run([
            'wget', '-L', '-nv', '-t', '3', '-nc', '-P', dl_dir, '-U', UA, img
        ])
        if p.returncode != 0:
            att += 1
            logging.error(f'Download failed: {url}, {img}, {att}')
            continue
        att = 0
        curr_page = int(url.split('-')[-1])
        url = next_regex.search(r.text).group(1)
        next_page = int(url.split('-')[-1])
        sleep(random() * .5)
