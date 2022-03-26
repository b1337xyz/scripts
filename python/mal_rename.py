#!/usr/bin/env python3
from sys import argv
import os
import re
import json
import urllib.parse
import subprocess as sp
from time import sleep
from difflib import SequenceMatcher as SM
from urllib.request import Request, urlopen

HOME = os.getenv('HOME')
HIST_FILE = '{}/.cache/mal_rename.hst'.format(HOME)
API_URL = 'https://api.jikan.moe/v4/anime'
UA = 'Mozilla/5.0 (X11; U; Linux i686) Gecko/20071127 Firefox/2.0.0.11'
BADCHAR = '~#%*{}\\/:<>?|\"\'`;'


def clear_text(txt):
    txt = txt.lower().replace(' - ', ' ')
    txt = txt.encode('ascii', 'ignore').decode()
    txt = re.sub('/', '', txt)
    txt = re.sub('_', ' ', txt)
    txt = re.sub(r'\[[^][]*\]', '', txt)
    txt = re.sub(r'\([^()]*\)', '', txt)
    txt = re.sub(r'(\+|\s)(bd|esp)(\s|$)', ' ', txt)
    txt = re.sub(r'(dvd|blu.?ray|especial|completo|legendado)', '', txt)
    txt = re.sub(r'(hdtv|\d{3,4}x\d{3,4}|\d{4}p|\d{4})', '', txt)
    txt = re.sub(r'(\(|\)|\[|\])', '', txt)
    txt = re.sub(r'\s\d{1,2}-\d{1,2}(\s|$)', ' ', txt)
    txt = re.sub(r'\s\+\s', ' ', txt)
    txt = re.sub(r'\s{2,}', ' ', txt)
    return txt.strip()


def clear_filename(txt):
    txt = txt.encode('ascii', 'ignore').decode()
    for i in BADCHAR:
        txt = txt.replace(i, ' ')
    txt = txt.replace('&', ' and ')
    txt = re.sub(r'^\.*', '', txt)
    txt = re.sub(r'\s{2,}', ' ', txt)
    return txt.strip()


main_lst = list()
if len(argv) > 1:
    main_lst = argv[1:]
else:
    print('running at \033[1;31m"{}"\033[m!'.format(os.getcwd()))
    print('Press ctrl-c to stop it')
    sleep(1)
    for inp in os.listdir():
        if len(inp) <= 3:
            continue
        if inp[0] == '.':
            continue
        main_lst.append(inp)

for main_idx, inp in enumerate(main_lst):
    print('[{:3}/{:3}] {}'.format(main_idx + 1, len(main_lst), inp))
    is_file = False
    if os.path.isfile(inp):
        cmd = ['file', '-Lbi', inp]
        mimetype = sp.run(cmd, stdout=sp.PIPE).stdout.decode()
        if 'video/' not in mimetype:
            continue
        is_file = True

    # if inp == [anime] > anime
    if len(re.sub(r'\[[^][]*\]', '', inp)) == 0:
        query = clear_text(inp[1:][:-1])
    else:
        query = clear_text(inp)

    if is_file:
        query = ''.join(query.split('.')[:-1])

    clean_query = query
    if len(query) < 3:
        print('MAL only processes queries with a minimum of 3 letters')
        continue

    query = urllib.parse.quote(query)
    url = '{}?q={}&limit=20'.format(API_URL, query)
    # print(url)

    r = Request(url, headers={'User-Agent': UA})
    sleep(1)
    while True:
        try:
            with urlopen(r, timeout=15) as data:
                j = json.load(data)
            break
        except Exception as err:
            print('\033[1;31m{}\033[m'.format(err))
            continue
    results = j['data']

    for i, d in enumerate(results):
        if d['type'] == 'Music':
            continue
        title = d['title']
        results[i]['title'] = clear_filename(title)

    new_results = list()
    for i in results:
        title = i['title']
        a = clear_text(title)
        b = clean_query
        r = SM(None, a, b).ratio()
        if r >= 0.99:
            new_results = [i]
            break
        elif r > 0.5:
            new_results.append(i)
    if new_results:
        results = new_results

    try:
        res = results[0]
    except IndexError:
        continue

    res = results[0]
    title = res['title']
    title = clear_filename(title)
    start_year = i["aired"]["prop"]["from"]["year"]

    out = '{} ({})'.format(title, start_year)

    if inp == out or os.path.exists(out):
        continue
    if os.path.isfile(inp):
        os.mkdir(out)

    if sp.run(['mv', '-vn', inp, out]).returncode != 0:
        break

    with open(HIST_FILE, 'a') as fp:
        fp.write('{} > {}\n'.format(inp, out))
