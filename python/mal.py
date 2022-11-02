#!/usr/bin/env python3
from optparse import OptionParser
from urllib.parse import quote
from urllib.request import urlopen
from thefuzz import process
import time
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

parser = OptionParser()
parser.add_option('--tolerance', type='int', default=10)
parser.add_option('-u', '--update', action='store_true', help='update cache')
parser.add_option('-l', '--limit', type='int', default=25)
parser.add_option('--id', type='int')
parser.add_option('--show-malid', action='store_true')
parser.add_option('-s', '--score', type='float')
parser.add_option('-m', '--max', help='max printed results',
    type='int', default=10)
parser.add_option('-t', '--type', type='string',
    help='tv, movie, ova, special, ona, music')
parser.add_option('-r', '--rating', type='string',
    help='g, pg, pg13, r17, r, rx')
parser.add_option('-o', '--order-by', type='string', default='',
    help='mal_id, title, type, rating, start_date, end_date,\
    episodes, score, scored_by, rank, popularity')
parser.add_option('--start-date', type='string', metavar='YYYY-MM-DD',
    default='', help='e.g 2022, 2005-05, 2005-01-01')
parser.add_option('--end-date', type='string', metavar='YYYY-MM-DD',
    default='', help='e.g 2022, 2005-05, 2005-01-01')
# parser.add_option('--nsfw', action='store_false', default=True)

opts, args = parser.parse_args()
query = quote(' '.join(args).lower())
url = API_URL.format(query, opts.limit)
if opts.order_by:
    url += f'&order_by={opts.order_by}'
if opts.start_date:
    url += f'&start_date={opts.start_date}'
if opts.end_date:
    url += f'&end_date={opts.end_date}'
if opts.type:
    url += f'&type={opts.type}'
if opts.rating:
    url += f'&rating={opts.rating}'
if opts.score:
    url += f'&score={opts.score}'
if opts.id:
    url = f'https://api.jikan.moe/v4/anime/{opts.id}'


data = dict()
if url in cache and not opts.update:
    data = cache[url]
else:
    print(url)
    with urlopen(url, timeout=15) as r:
        j = json.load(r)['data']
        for i in [j] if opts.id else j:
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
                'year':     year if year else '?',
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
            ' '.join(args),
            {k: v['title'] for k,v in data.items()},
            limit=len(data)
        ) if i[1] > opts.tolerance
    ]
else:
    titles = data.keys()

max_len = max(len(i['title']) for i in data.values()) + 7

for k in titles[:opts.max]:
    obj = data[k]
    title = obj['title']
    title += ' ({})'.format(obj["year"])
    print('{0:{1}} | {2:8} | {3:<4} | {4:<4} | {5}'.format(
        title, max_len, obj['type'],
        obj['episodes'], obj['score'], obj['rating']
    ), end=f' | {k}\n' if opts.show_malid else '\n')
