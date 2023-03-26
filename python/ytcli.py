#!/usr/bin/env python3
from optparse import OptionParser
from html import unescape
from random import choice, shuffle
from time import sleep
import googleapiclient.discovery
import json
import os
import socket
import subprocess as sp
import sys

# HOW TO GET THE API_KEY -> https://developers.google.com/youtube/v3/quickstart/python
# before running this start mpv with:
# mpv --keep-open=yes --idle=yes --ytdl-format="ba*" \
#     --cache=yes --no-video --input-ipc-server=<SOCKET_PATH>

if os.system('pgrep -f "mpv --profile=radio" >/dev/null') != 0:
    sp.Popen(['mpv', '--profile=radio'],
             shell=True, stdout=sp.DEVNULL, stderr=sp.DEVNULL)

TMPDIR = os.getenv('TMPDIR', '/tmp')
PLAYLIST = os.path.join(TMPDIR, 'mpvradio.m3u')
SOCKET_PATH = os.path.join(TMPDIR, 'mpvradio')
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.cache/yt_history')
CONF = os.path.join(HOME, '.config/.ytapi')
SAVE = os.path.join(HOME, '.config/ytcli.json')
if not os.path.exists(CONF):
    API_KEY = input('API KEY: ').strip()
    with open(CONF, 'w') as fp:
        fp.write(API_KEY)
else:
    with open(CONF, 'r') as fp:
        API_KEY = fp.readline().strip()


def run(prog: str, args: list, opts: list):
    proc = sp.Popen(
       [prog] + opts,
       stdin=sp.PIPE, stdout=sp.PIPE,
       universal_newlines=True
    )
    out = proc.communicate('\n'.join(args))
    if proc.returncode not in [0, 1]:
        sys.exit(proc.returncode)
    return [i for i in out[0].split('\n') if i]


def parse_arguments():
    parser = OptionParser()
    parser.add_option('--dmenu', action='store_true')
    parser.add_option('--fzf', action='store_true', default=True)
    parser.add_option('-r', '--random', action='store_true')
    parser.add_option('-l', '--history', action='store_true')
    parser.add_option('-a', '--all', action='store_true')
    parser.add_option('-s', '--shuffle', action='store_true',
        help='shuffle playlist')
    parser.add_option('--long', action='store_true',
        help='Only include videos longer than 20 minutes.')
    parser.add_option('--save', action='store_true',
        help='save playlist')
    parser.add_option('--load', action='store_true',
        help='load playlist')
    return parser.parse_args()


def load_history():
    try:
        with open(HIST, 'r') as fp:
            hist = [i.strip() for i in fp.readlines() if i][::-1]
        uniq_hist = list()
        for i in hist:
            if i not in uniq_hist:
                uniq_hist.append(i)
        return uniq_hist
    except FileNotFoundError:
        return list()


def main():
    opts, args = parse_arguments()
    try:
        with open(SAVE, 'r') as fp:
            save = json.load(fp)
    except FileNotFoundError:
        save = dict()

    hist = load_history()
    hist_len = len(hist)
    height = str(hist_len) if hist_len <= 10 else '10'

    if args:
        query = ' '.join(args)
    elif opts.load:
        keys = list(save.keys())
        query = run('fzf', keys, [
            '--height', height, '--prompt', 'query: ',
            '--print-query'
        ])[-1]
    elif opts.dmenu:
        if opts.history and hist:
            query = run('dmenu', hist, [
                '-i', '-c', '-l', height, '-p', 'search:'
            ])[-1]
        else:
            query = run('dmenu', [], ['-c', '-i', '-p', 'search:'])[-1]
    elif hist:
        query = run('fzf', hist, [
            '--bind', 'tab:print-query',
            '--height', height, '--prompt', 'search: ',
            '--print-query'
        ])[-1]
    else:
        query = input('search: ').strip()

    with open(HIST, 'a') as fp:
        fp.write(query + '\n')

    if not opts.load:
        youtube = googleapiclient.discovery.build(
            'youtube', 'v3', developerKey=API_KEY)

        # videoCategoryId='10', # Music
        request = youtube.search().list(
            q=query.replace(' ', '-'),
            type='video,playlist',
            part="id,snippet",
            safeSearch='none',
            videoDuration='long' if opts.long else 'any',
            maxResults=40
        )
        response = request.execute()

        videos = dict()
        for i in response['items']:
            title = unescape(i['snippet']['title'])
            if 'playlistId' in i['id']:
                _id = i['id']['playlistId']
            else:
                _id = i['id']['videoId']
            c = 0
            _title = title
            while title in videos:
                title = f'{_title} {c}'
                c += 1
            videos[title] = _id
        keys = list(videos.keys())

    if opts.load:
        videos = save[query]
        output = list(videos.keys())
    elif opts.shuffle:
        shuffle(keys)
        output = keys
    elif opts.random:
        output = [choice(keys)]
    elif opts.all:
        output = keys
    elif opts.dmenu:
        output = run('dmenu', keys, ['-c', '-i', '-l', '25'])
    else:
        output = run('fzf',   keys, ['-m', '--height', '25'])

    if opts.save:
        save[query] = dict()
        for k in output:
            save[query][k] = videos[k]
        with open(SAVE, 'w') as fp:
            json.dump(save, fp)

    with open(PLAYLIST, "w") as fp:
        fp.write("#EXTM3U\n")
        for k in output:
            url = f'https://www.youtube.com/watch?v={videos[k]}'
            fp.write(f"#EXTINF:0, {k}\n{url}\n")

    mpv = socket.socket(socket.AF_UNIX)
    mpv.connect(SOCKET_PATH)
    cmd = {"command": ["loadlist", PLAYLIST]}
    mpv.send(json.dumps(cmd).encode('utf-8') + b'\n')
    mpv.close()


if __name__ == '__main__':
    main()
