#!/usr/bin/env python3
from optparse import OptionParser
from urllib.parse import quote
from thefuzz import process
from time import sleep
import requests
import subprocess as sp
import json
import re
import os

parser = OptionParser()
parser.add_option('-a', '--use-anilist', action='store_true',
                  help='usa anilist api')
parser.add_option('-y', '--dont-ask', action='store_true',
                  help='don\'t ask')
parser.add_option('--year', type='int')
opts, args = parser.parse_args()

YEAR = opts.year
USE_ANILIST = opts.use_anilist
JIKAN_URL = "https://api.jikan.moe/v4/anime?q={}&limit=20"
ANILIST_URL = 'https://graphql.anilist.co'
RE_EXT = re.compile(r'.*\.(?:mkv|avi|rmvb|mp4)$')
HOME = os.getenv('HOME')
RED = '\033[1;31m'
GRN = '\033[1;32m'
BLU = '\033[1;34m'
END = '\033[m'


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


def cleanup_string(string: str) -> str:
    s = re.sub(r'\.(?:mkv|avi|rmvb|mp4)$', '', string).lower()
    s = re.sub(r'\[[^][]*\]', '', s)
    s = re.sub(r'\([^()]*\)', '', s)
    s = re.sub(r'episode.\d+', '', s)
    s = re.sub(r'epis.dio.\d+', '', s)
    s = re.sub(r'\d+(?:v\d+)?', '', s)
    s = re.sub(r's\d+e\d+', '', s)
    s = re.sub(r'[_\.]', ' ', s)
    s = re.sub(r"(?ui)\W", ' ', s)
    s = s.encode('ascii', 'ignore').decode()
    s = re.sub(r'\s{2,}', ' ', s).strip()
    if len(s) < 3:
        print('String length less than 3:', string)
        return
    return s


def request_jikan(query: str) -> dict:
    url = JIKAN_URL.format(quote(query))
    r = requests.get(url)
    return r.json()['data']


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
    print(f'move {files[0]}... ({len(files)}) ->\n\t{BLU}{folder}{END}')
    if not opts.dont_ask:
        if input('Are you sure? [y/N] ').lower().strip() != 'y':
            return

    os.mkdir(folder)
    sp.run(['mv', '-vn'] + files + [folder])


def main():
    uniq = dict()
    for f in os.listdir() if not args else args:
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
        print(f'{RED}< {files[0]}{END}\n{GRN}> {query}{END}')
        if USE_ANILIST:
            data = request_anilist(query)
        else:
            data = request_jikan(query)
        sleep(0.5)

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
