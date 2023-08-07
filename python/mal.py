#!/usr/bin/env python3
from argparse import ArgumentParser
from urllib.parse import quote
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from thefuzz import process
from shutil import copy
import json
import re
import os

API_URL = "https://api.jikan.moe/v4/anime?q={}&limit={}"
HOME = os.getenv('HOME')
CACHE = os.path.join(HOME, '.cache/mal.json')

try:
    with open(CACHE, 'r') as fp:
        cache = json.load(fp)
except FileNotFoundError:
    cache = dict()
copy(CACHE, f'{CACHE}.bak')

parser = ArgumentParser(usage='%(prog)s [options] <search>')
parser.add_argument('--tolerance', type=int, default=10)
parser.add_argument('-u', '--update', action='store_true', help='update cache')
parser.add_argument('-l', '--limit', type=int, default=25)
parser.add_argument('--id', type=int)
parser.add_argument('--show-malid', action='store_true')
parser.add_argument('-s', '--score', type=float)
parser.add_argument('-m', '--max', help='max printed results',
                  type=int, default=10)
parser.add_argument('-t', '--type', type=str,
                  help='tv, movie, ova, special, ona, music')
parser.add_argument('-r', '--rating', type=str,
                  help='g, pg, pg13, r17, r, rx')
parser.add_argument('-o', '--order-by', type=str, default='',
                  help='mal_id, title, type, rating, start_date, end_date,\
                  episodes, score, scored_by, rank, popularity')
parser.add_argument('--start-date', type=str, metavar='YYYY-MM-DD',
                  default='', help='e.g 2022, 2005-05, 2005-01-01')
parser.add_argument('--end-date', type=str, metavar='YYYY-MM-DD',
                  default='', help='e.g 2022, 2005-05, 2005-01-01')
parser.add_argument('--sort-by-year', action='store_true')
parser.add_argument('search', metavar='search', type=str, nargs='+',
                    help='Search title')
# parser.add_argument('--nsfw', action='store_false', default=True)

args = parser.parse_args()
query = ' '.join(args.search).lower()
url = API_URL.format(quote(query), args.limit)
if args.order_by:
    url += f'&order_by={args.order_by}'
if args.start_date:
    url += f'&start_date={args.start_date}'
if args.end_date:
    url += f'&end_date={args.end_date}'
if args.type:
    url += f'&type={args.type}'
if args.rating:
    url += f'&rating={args.rating}'
if args.score:
    url += f'&score={args.score}'
if args.id:
    url = f'https://api.jikan.moe/v4/anime/{args.id}'

def get(url):
    r = urlopen(Request(url), timeout=15)
    resp = json.load(r)

    if resp.get('error') is not None:
        print(json.dumps(resp, indent=2))
        exit(1)
    return resp.get('data')


data = dict()
if url in cache and not args.update:
    data = cache[url]
else:
    r = get(url)
    for i in [r] if args.id else r:
        mal_id = str(i['mal_id'])
        title = re.sub(r"(?ui)\W", ' ', i['title'])
        title = title.encode('ascii', 'ignore').decode()
        title = re.sub(r'\s{2,}', ' ', title).strip()
        year = i['year']
        year = i['aired']['prop']['from']['year'] if not year else year
        rating = i['rating'].split()[0] if i['rating'] else '?'
        data[mal_id] = {
            'title':    title,
            'type':     i['type'] if i['type'] else '?',
            'episodes': i['episodes'] if i['episodes'] else 0,
            'rating':   rating,
            'year':     int(year) if year else '?',
            'score':    i['score'] if i['score'] else '?'
        }

    if not data:
        print('Nothing to do...')
        exit(0)

    cache[url] = data
    with open(CACHE, 'w') as fp:
        json.dump(cache, fp)

if args:
    titles = [
        i[-1] for i in process.extract(
            query,
            {k: v['title'] for k, v in data.items()},
            limit=len(data)
        ) if i[1] > args.tolerance
    ]
else:
    titles = list(data.keys())

max_len = max(len(i['title']) for i in data.values()) + 7
if args.sort_by_year:
    titles = sorted(
        [k for k in data if data[k]['year'] != '?'],
        key=lambda k: int(data[k]['year'])
    )
for k in titles[:args.max]:
    obj = data[k]
    title = obj['title']
    title += ' ({})'.format(obj["year"])
    print('{0:{1}} | {2:8} | {3:<4} | {4:<4} | {5}'.format(
        title, max_len, obj['type'],
        obj['episodes'], obj['score'], obj['rating']
    ), end=f' | {k}\n' if args.show_malid else '\n')
