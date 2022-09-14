#!/usr/bin/env python3
from bs4 import BeautifulSoup as BS
from sys import argv
from urllib.request import Request, urlopen
import os
import re
import subprocess as sp
assert len(argv) > 1

UA = "Mozilla/5.0 (X11; U; Linux i686) Gecko/20071127 Firefox/2.0.0.11"


def get_soup(url):
    r = Request(url, headers={'User-Agent': UA})
    with urlopen(r) as data:
        return BS(data.read().decode(), 'html.parser')


url = argv[1]
thread = os.path.abspath(re.search(r'/thread/(\d*)', url).group(1))
if not os.path.exists(thread):
    os.mkdir(thread)
soup = get_soup(url)
posts = [
    post.text.strip().replace('\n', '')
    for post in soup.findAll('blockquote', {'class': 'postMessage'})
]

for post in posts:
    for magnet in re.findall(r'magnet:\?xt=urn:btih:[A-z0-9]+', post):
        try:
            sp.run([
                'aria2c',
                '-d', thread,
                '--bt-save-metadata',
                '--bt-metadata-only',
                '--bt-stop-timeout=90',
                magnet
            ])
        except Exception as err:
            print("ERROR: {}".format(err))
