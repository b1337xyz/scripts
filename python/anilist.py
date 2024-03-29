#!/usr/bin/env python3
from optparse import OptionParser
from thefuzz import process
import requests
import re
import os

API_URL = 'https://graphql.anilist.co'
HOME = os.getenv('HOME')

parser = OptionParser()
parser.add_option('--tolerance', type='int', default=10)
parser.add_option('--show-malid', action='store_true')
parser.add_option('-l', '--limit', type='int', default=10)
parser.add_option('-m', '--max', type='int', default=10,
                  help='max printed results')
opts, args = parser.parse_args()

api_query = '''
query ($id: Int, $page: Int, $perPage: Int, $search: String) {
    Page (page: $page, perPage: $perPage) {
        media (id: $id, search: $search, sort: SEARCH_MATCH, type: ANIME) {
            id
            idMal
            title {
                romaji
            }
            startDate {
                year
            }
            episodes
            averageScore
        }
    }
}
'''
api_query_by_malid = '''
query ($id: Int, $idMal: Int, $page: Int, $perPage: Int) {
    Page (page: $page, perPage: $perPage) {
        media (id: $id, idMal: $idMal, sort: SEARCH_MATCH, type: ANIME) {
            id
            idMal
            title {
                romaji
            }
            startDate {
                year
            }
            episodes
            averageScore
        }
    }
}
'''


def search_by_id(mal_id):
    variables = {
        'idMal': int(mal_id),
        'page': 1,
        'perPage': opts.limit,
    }
    r = requests.post(API_URL, json={
        'query': api_query_by_malid, 'variables': variables
    })
    return r.json()['data']['Page']['media']


def search(query):
    variables = {
        'search': query,
        'page': 1,
        'perPage': opts.limit,
    }
    r = requests.post(API_URL, json={
        'query': api_query, 'variables': variables
    })
    return r.json()['data']['Page']['media']


query = ' '.join(args).lower()
if query.isdigit():
    print('searching by id')
    malid = args[0]
    results = search_by_id(malid)
else:
    results = search(query)

data = dict()
for i in results:
    malid = i['idMal']
    score = i['averageScore']
    episodes = i['episodes']
    title = re.sub(r"(?ui)\W", ' ', i['title']['romaji'])
    title = title.encode('ascii', 'ignore').decode()
    title = re.sub(r'\s{2,}', ' ', title).strip()
    data[malid] = {
        'id':       i['id'],
        'title':    title,
        'year':     i['startDate']['year'],
        'episodes': episodes if episodes else '?',
        'score':    score if score else '?'
    }

if query.isdigit():
    titles = list(data.keys())
else:
    titles = [
        i[-1] for i in process.extract(
            query,
            {k: v['title'] for k, v in data.items()},
            limit=len(results)
        ) if i[1] > opts.tolerance
    ]
if not titles:
    exit(0)

max_len = max(len(i['title']) for i in data.values()) + 7
for k in titles[:opts.max]:
    obj = data[k]
    title = obj['title']
    title += ' ({})'.format(obj["year"])
    # print(obj['id'], end=' ')
    print('{0:{1}} | {2:>4} | {3}'.format(
        title, max_len, obj['episodes'], obj['score']
    ), end=f' | {k}\n' if opts.show_malid else '\n')
