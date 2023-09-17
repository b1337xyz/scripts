#!/usr/bin/env python3
from argparse import ArgumentParser
from urllib.parse import quote
from thefuzz import process
from time import sleep
from shutil import which
from datetime import datetime
import requests
import subprocess as sp
import re
import os

parser = ArgumentParser()
parser.add_argument('-a', '--use-anilist', action='store_true',
                    help='use anilist api')
parser.add_argument('-y', '--dont-ask', action='store_true',
                    help='don\'t ask')
parser.add_argument('-l', '--link', action='store_true',
                    help='make a symbolic link')
parser.add_argument('-p', '--path', type=str, default='.',
                    help='path to folder (default: current directory)')
parser.add_argument('-r', '--rename', action='store_true',
                    help='rename/link file itself')
parser.add_argument('-f', '--files-only', action='store_true')
parser.add_argument('--exclude', nargs='*')
parser.add_argument('--fzf', action='store_true')
parser.add_argument('--year', type=int, default=-1)
parser.add_argument('argv', nargs='*')
args = parser.parse_args()
argv = args.argv

assert os.path.isdir(args.path)
if args.rename:
    assert len(args.argv) > 0
    assert all([os.path.isdir(i) for i in args.argv]), \
        "All arguments must be a directory."
if args.fzf:
    assert which('fzf')

YEAR_NOW = datetime.now().year
USE_ANILIST = args.use_anilist
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
        r'(?:animesplus|tnnac.animax|softsub|test.kun|(?:multi.?)?mattmurdock|abertura|encerramento|unico)',  # noqa: E501
        r'(?:xvid|\w fansub| tv| dvd| hd|blu.?ray| \d+p|flac|opus)',  # noqa: E501
        r'(?:epis.d[ie]o|\sep?|sp|season)?\s?\d+(?:v\d+|final)?',
        r' \d+nd',
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
        'perPage': 20
    }
    r = requests.post(ANILIST_URL, json={
        'query': api_query, 'variables': variables
    })
    return r.json()['data']['Page']['media']


def parse_data(data: list, file_count: int) -> dict:
    parsed_data = dict()
    for i in sorted(data,
                    key=lambda x: file_count >= x.get('espisodes', 0),
                    reverse=True):

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
            if (year := i.get('year')) is None:
                year = i['aired']['prop']['from']['year']

        if year is not None:
            if int(year) > YEAR_NOW or args.year > int(year):
                continue

        parsed_data[clean_title] = (title, year, episodes)
    return parsed_data


def fuzzy_sort(query: str, choices: list) -> str:
    try:
        return [i[0]
                for i in process.extract(query, choices, limit=len(choices))
                if i[1] >= 90][0]
    except IndexError:
        return choices[0]


def ask(question: str) -> bool:
    if args.dont_ask:
        return True
    return input(question + ' [y/N] ').lower().strip() == 'y'


def move_to(files: list, folder: str):
    if args.rename and len(files) > 1:
        for i in files:
            move_to([i], folder)
        return

    folder = os.path.join(args.path, folder)
    if os.path.exists(folder):
        if not (os.path.isdir(folder) and ask(f'{folder} exists, move files to it?')):  # noqa: E501
            c = 0
            _copy = folder
            while os.path.exists(folder) and (c := c + 1):
                folder = f'{_copy} ({c})'

    print(f'{files[0]}... ({len(files)}) ->\n\t{BLU}{folder}{END}')
    if not args.rename and not os.path.exists(folder):
        os.mkdir(folder)

    cmd = ['ln', '-rvs'] if args.link else ['mv', '-vn']
    sp.run(cmd + files + [folder])


def fzf(args: list, prompt: str) -> str:
    try:
        proc = sp.Popen(
           ['fzf', '--height', '10', '--prompt', prompt],
           stdin=sp.PIPE,
           stdout=sp.PIPE,
           universal_newlines=True
        )
        out = proc.communicate('\n'.join(args[::-1]))
        if proc.returncode != 0:
            return None
        return [i for i in out[0].split('\n') if i]
    except KeyboardInterrupt:
        pass


def main():
    uniq = dict()
    exclude = [os.path.basename(os.path.realpath(i)) for i in args.exclude]
    print(exclude)
    for f in os.listdir() if not argv else argv:
        f = os.path.basename(os.path.realpath(f))
        if f in exclude:
            print(f'skipping {f}')
            continue

        if f.startswith('.') or (args.files_only and not os.path.isfile(f)):
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
        if ask('Change query?'):
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

        if args.fzf and len(data) > 1:
            out = fzf([
                f'{title} ({year})' for title, year, _ in data.values()
            ], prompt=f'Query: {query}> ')
            if not out:
                continue
            folder = out[0]
        else:
            k = fuzzy_sort(query, list(data.keys()))
            title, year, _ = data[k]
            folder = f'{title} ({year})'

        move_to(files, folder)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
