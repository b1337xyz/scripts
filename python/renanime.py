#!/usr/bin/env python3
from optparse import OptionParser
from urllib.parse import quote
from thefuzz import process
from time import sleep
from shutil import which
import requests
import subprocess as sp
import re
import os

parser = OptionParser()
parser.add_option('-a', '--use-anilist', action='store_true',
                  help='use anilist api')
parser.add_option('-y', '--dont-ask', action='store_true',
                  help='don\'t ask')
parser.add_option('-l', '--link', action='store_true',
                  help='make a symbolic link')
parser.add_option('-p', '--path', type='string', default='.',
                  help='path to folder (default: current directory)')
parser.add_option('-r', '--rename', action='store_true',
                  help='rename/link file itself instead of moving to a folder')
parser.add_option('-f', '--files-only', action='store_true')
parser.add_option('--fzf', action='store_true')
parser.add_option('--year', type='int')
opts, args = parser.parse_args()

assert os.path.isdir(opts.path)
if opts.rename:
    assert len(args) > 0
    assert all([os.path.isdir(i) for i in args])
if opts.fzf:
    assert which('fzf')

YEAR = opts.year
USE_ANILIST = opts.use_anilist
JIKAN_URL = "https://api.jikan.moe/v4/anime?q={}&limit=20"
ANILIST_URL = 'https://graphql.anilist.co'
RE_EXT = re.compile(r'\.(?:mkv|avi|rmvb|mp4|webm|m4v|ogm)$')
HOME = os.getenv('HOME')
RED = '\033[1;31m'
GRN = '\033[1;32m'
BLU = '\033[1;34m'
PUR = '\033[1;35m'
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
            episodes
        }
    }
}
'''


def cleanup_filename(string: str) -> str:
    patterns = [
        RE_EXT.pattern,
        r'\[[^][]*\]',
        r'\([^()]*\)',
        r'\.(?:bd|flac(?:\d\.\d)?|hevc|x265)\.',
        r'[_\-\.]',
        r's\d+e\d+',
        r'(?:tnnac.animax|test.kun|(?:multi.?)?mattmurdock|abertura|encerramento|unico)',  # noqa: E501
        r'(?:xvid|\w fansub| tv| dvd| hd|blu.?ray| \d+p|flac|opus)',  # noqa: E501
        r'(?:epis.d[ie]o|\sep?|sp)?\s?\d+.?(?:v\d+|final)?',
        r"(?ui)\W",
    ]

    # string = re.sub(r's(\d+?)e\d+', r'season \1', string).lower()
    string = re.sub(r'/+$', '', string).split('/')[-1].lower().replace(
        'especial', 'special')
    for p in patterns:
        new_string = re.sub(p, ' ', string).strip()
        new_string = re.sub(r'\s{2,}', ' ', new_string)

        if new_string and new_string != string:
            print(f'"{RED}{string}{END}" -> {p} -> "{GRN}{new_string}{END}"')
            string = new_string

    string = string.encode('ascii', 'ignore').decode().strip()
    if len(string) < 3:
        print('String length less than 3')
        return input('query: ').strip()
    return string


def cleanup_title(string: str) -> str:
    patterns = [
        r'\[[^][]*\]',
        r'\([^()]*\)',
        r"(?ui)\W"
    ]
    for p in patterns:
        string = re.sub(p, ' ', string)
    string = re.sub(r'\s{2,}', ' ', string).strip()
    return string.encode('ascii', 'ignore').decode().lower()


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


def parse_data(data: dict, file_count: int) -> list:
    parsed_data = list()
    for i in data:
        if USE_ANILIST:
            title = i['title']['romaji']
        else:
            title = i['title']

        title = re.sub(r"(?ui)\W", ' ', title)
        title = title.encode('ascii', 'ignore').decode()
        title = re.sub(r'\s{2,}', ' ', title).strip()
        clean_title = cleanup_title(title)
        episodes = i['episodes']

        if USE_ANILIST:
            year = i['startDate']['year']
        else:
            year = i['year']
            year = i['aired']['prop']['from']['year'] if not year else year

        if YEAR and year and YEAR != int(year):
            continue

        parsed_data.append((clean_title, title, year, episodes))

    parsed_data = sorted(parsed_data,
                         key=lambda x: x[-1] == file_count, reverse=True)

    return parsed_data


def fuzzy_sort(query: str, data: list) -> list:
    return [
        i[0] for i in process.extract(
            query, data, limit=len(data)
        ) if i[1] >= 90
    ]


def ask(question: str) -> bool:
    if opts.dont_ask:
        return True
    return input(question + ' [y/N] ').lower().strip() == 'y'


def move_to(files: list, folder: str):
    folder = os.path.join(opts.path, folder)
    if os.path.exists(folder):
        if not os.path.isdir(folder) or \
           not ask(f'{folder} already exists, move files to it?'):
            c = 1
            _copy = folder
            while os.path.exists(folder):
                folder = f'{_copy} ({c})'
                c += 1

    print(f'{files[0]}... ({len(files)}) ->\n\t{BLU}{folder}{END}')
    if not ask('Are you sure?'):
        return

    if not opts.rename and not os.path.exists(folder):
        os.mkdir(folder)

    cmd = ['ln', '-rvs'] if opts.link else ['mv', '-vn']
    sp.run(cmd + files + [folder])


def fzf(args: list, prompt: str) -> str:
    try:
        proc = sp.Popen(
           ['fzf', '--prompt', prompt],
           stdin=sp.PIPE,
           stdout=sp.PIPE,
           universal_newlines=True
        )
        out = proc.communicate('\n'.join(args))
        if proc.returncode != 0:
            return None
        return [i for i in out[0].split('\n') if i]
    except KeyboardInterrupt:
        pass


def main():
    uniq = dict()
    for f in os.listdir() if not args else args:
        if f.startswith('.') or (opts.files_only and not os.path.isfile(f)):
            continue
        string = cleanup_filename(f)
        if not string:
            continue
        elif string in uniq:
            uniq[string].append(f)
        else:
            uniq[string] = [f]

    print(f'--- {len(uniq)} unique strings')
    for query in uniq:
        files = uniq[query]
        print(f'{RED}< {files[0]}{END}\n{GRN}> {query}{END}')
        if not ask('Is that right?'):
            query = input('Query: ').strip()
        if not query:
            continue

        if USE_ANILIST:
            data = request_anilist(query)
        else:
            data = request_jikan(query)
        sleep(0.5)

        if not data:
            print(f'nothing found: "{query}"')
            continue

        data = parse_data(data, len(files))
        if not data:
            print(f'nothing to do: "{query}"')
            continue

        if opts.fzf and len(data) > 1:
            folder = fzf([
                f'{title} ({year})' for _, title, year, _ in data
            ], prompt=f'Query: {query}>')
            if not folder:
                continue
            folder = folder[0]
        else:
            fuzz = fuzzy_sort(query, data)
            if fuzz:
                _, title, year, _ = fuzz[0]
            else:
                _, title, year, _ = data[0]
            folder = f'{title} ({year})'

        move_to(files, folder)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
