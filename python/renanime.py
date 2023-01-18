#!/usr/bin/env python3
from optparse import OptionParser
from urllib.parse import quote
from urllib.request import urlopen
from thefuzz import process
from time import sleep
from sys import argv
from shutil import copy
import requests
import subprocess as sp
import json
import re
import os

parser = OptionParser()
parser.add_option('-a', '--use-anilist', action='store_true')
parser.add_option('--year', type='int', default=0)
parser.add_option('--update', action='store_true')
opts, args = parser.parse_args()

YEAR = opts.year if opts.year > 0 else None
USE_ANILIST = opts.use_anilist
JIKAN_URL = "https://api.jikan.moe/v4/anime?q={}&limit=20"
ANILIST_URL = 'https://graphql.anilist.co'
RE_EXT = re.compile(r'.*\.(?:mkv|avi|rmvb|mp4)$')
HOME = os.getenv('HOME')
CACHE = os.path.join(HOME, '.cache/jikan.json')

api_query = '''
query ($id: Int, $page: Int, $perPage: Int, $search: String) {
    Page (page: $page, perPage: $perPage) {
        media (id: $id, search: $search, sort: SEARCH_MATCH, type: ANIME) {
            title {
                romaji
            }
            startDate {
                year
            }
        }
    }
}
'''


def cleanup_string(string):
    s = re.sub(r'\.(?:mkv|avi|rmvb|mp4)$', '', string).lower()
    s = re.sub(r'\[[^][]*\]', '', s)
    s = re.sub(r'\([^()]*\)', '', s)
    s = re.sub(r'episode.\d+', '', s)
    s = re.sub(r'epis.dio.\d+', '', s)
    s = re.sub(r'[_ ]-[_ ]\d+', '', s)
    s = re.sub(r's\d+e\d+', '', s)
    s = re.sub(r' \d+ ', ' ', s)
    s = re.sub(r' \d+v\d ', ' ', s)
    s = re.sub(r' - \d+', ' ', s)
    s = re.sub(r' - \d+v\d+', ' ', s)
    s = re.sub(r'[_\-\.]', ' ', s)
    s = re.sub(r"(?ui)\W", ' ', s)
    s = s.encode('ascii', 'ignore').decode()
    s = re.sub(r'\s{2,}', ' ', s).strip()
    if len(s) < 3:
        print('String length less than 3:', string)
        return
    return s


def load_json(file: str) -> dict:
    try:
        with open(file, 'r') as fp:
            return json.load(fp)
    except Exception as err:
        print(err)
        return dict()


def dump_json(data: dict, file: str):
    copy(file, f'{file}.bak')
    with open(file, 'w') as fp:
        json.dump(data, fp)


def request_jikan(query: str) -> dict:
    try:
        with open(CACHE, 'r') as fp:
            cache = json.load(fp)
    except FileNotFoundError:
        cache = dict()
        sleep(0.6)

    url = JIKAN_URL.format(quote(query))
    if url in cache and not opts.update:
        cache = load_json(CACHE)
        return cache[url]

    with urlopen(url) as r:
        data = json.load(r)['data']
    sleep(0.6)

    cache[url] = data
    dump_json(cache, CACHE)
    return data


def request_anilist(query: str) -> dict:
    variables = {
        'search': query,
        'page': 1,
        'perPage': 20,
    }
    r = requests.post(ANILIST_URL, json={
        'query': api_query, 'variables': variables
    })
    return r.json()['data']['Page']['media']


def parse_data(data: dict) -> list:
    parsed_data = list()
    for i in data:
        if USE_ANILIST:
            title = i['title']['romaji']
        else:
            title = i['title']

        title = re.sub(r"(?ui)\W", ' ', title)
        title = title.encode('ascii', 'ignore').decode()
        title = re.sub(r'\s{2,}', ' ', title).strip()

        if USE_ANILIST:
            year = i['startDate']['year']
        else:
            year = i['year']
            year = i['aired']['prop']['from']['year'] if not year else year

        if YEAR and year and YEAR != int(year):
            continue

        parsed_data.append((cleanup_string(title), title, year))
    return parsed_data


def fuzzy_sort(query: str, data: list) -> list:
    return [
        i[0] for i in process.extract(
            query, data, limit=len(data)
        ) if i[1] >= 90
    ]


def move_files(files: list, folder: str):
    print(f'move {files[0]}... ({len(files)}) > {folder}')
    if input('Are you sure? [y/N] ').lower().strip() != 'y':
        return

    os.mkdir(folder)
    sp.run(['mv', '-vn'] + files + [folder])


def main():
    uniq = dict()
    for f in os.listdir():
        if not os.path.isfile(f) or not RE_EXT.match(f):
            continue

        string = cleanup_string(f)
        if not string:
            continue
        elif string in uniq:
            uniq[string].append(f)
        else:
            uniq[string] = [f]

    for query in uniq:
        files = uniq[query]
        print(f'{files[0]} > {query}')
        if USE_ANILIST:
            data = request_anilist(query)
        else:
            data = request_jikan(query)

        if not data:
            print(f'nothing found: "{query}"')
            continue

        data = parse_data(data)
        if not data:
            print(f'nothing to do: "{query}"')
            continue

        fuzz = fuzzy_sort(query, data)
        if fuzz:
            _, title, year = fuzz[0]
        else:
            _, title, year = data[0]

        folder = f'{title} ({year})'
        move_files(files, folder)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
