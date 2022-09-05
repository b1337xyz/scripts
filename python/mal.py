#!/usr/bin/env python3
from optparse import OptionParser
from urllib.parse import quote
from urllib.request import urlopen
from fuzzywuzzy import process
import time
import json
import re
import os

API_URL = "https://api.jikan.moe/v4/anime?q={}&limit={}&sfw={}"
HOME = os.getenv('HOME')
CACHE = os.path.join(HOME, '.cache/jikan.json')
try:
    COLS = os.get_terminal_size().columns
except OSError:
    COLS = 150
COLS //= 2

try:
    with open(CACHE, 'r') as fp:
        cache = json.load(fp)
except FileNotFoundError:
    cache = dict()

parser = OptionParser()
parser.add_option('--tolerance', type='int', default=10)
parser.add_option('-u', '--update', action='store_true', help='update cache')
parser.add_option('-l', '--limit', type='int', default=25)
parser.add_option('-t', '--type', type='string',
    help='tv, movie, ova, special, ona, music')
parser.add_option('-r', '--rating', type='string',
    help='g, pg, pg13, r17, r, rx')
parser.add_option('-s', '--score', type='float')
parser.add_option('-o', '--order-by', type='string', default='',
    help='mal_id, title, type, rating, start_date, end_date,\
    episodes, score, scored_by, rank, popularity')
parser.add_option('--start-date', type='string', metavar='YYYY-MM-DD',
    default='', help='e.g 2022, 2005-05, 2005-01-01')
parser.add_option('--end-date', type='string', metavar='YYYY-MM-DD',
    default='', help='e.g 2022, 2005-05, 2005-01-01')
parser.add_option('--nsfw', action='store_false', default=True)
opts, args = parser.parse_args()
query = quote(' '.join(args))
url = API_URL.format(query, opts.limit, str(opts.nsfw).lower())
if opts.order_by:
    url += f'&order_by={opts.order_by}'
if opts.start_date:
    url += f'&start_date={opts.start_date}'
if opts.end_date:
    url += f'&end_date={opts.end_date}'
if opts.type:
    url += f'&type={opts.type}'
if opts.rating:
    url += f'&type{opts.rating}'
if opts.score:
    url += f'&score={opts.score}'

data = dict()
regex = re.compile(r"(?ui)\W")
if url in cache and not opts.update:
    data = cache[url]
else:
    print(url)
    with urlopen(url, timeout=15) as r:
        for i in json.load(r)['data']:
            mal_id = str(i['mal_id'])
            title = regex.sub(" ", i['title'])
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

for k in titles:
    obj = data[k]
    title = obj['title']
    title = title if len(title) + 7 < COLS else title[:COLS - 10] + '...'
    title += ' ({})'.format(obj["year"])
    print('{0:{1}} | {2:8} | {3:<4} | {4:<4} | {5}'.format(
        title, COLS, obj['type'], obj['episodes'], obj['score'], obj['rating']
    ))
