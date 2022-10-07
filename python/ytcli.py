#!/usr/bin/env python3
from optparse import OptionParser
from html import unescape
from random import choice
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

SOCKET_PATH = '/tmp/mpvradio'
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.cache/yt_history')
CONF = os.path.join(HOME, '.config/.ytapi')
if not os.path.exists(CONF):
    API_KEY = input('API KEY: ').strip()
    with open(CONF, 'w') as fp:
        fp.write(API_KEY)
else:
    API_KEY = open(CONF, 'r').readline().strip()


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
    parser.add_option('--random', action='store_true')
    parser.add_option('--long', action='store_true',
        help='Only include videos longer than 20 minutes.')
    parser.add_option('--history', action='store_true')
    parser.add_option('--all', action='store_true')
    return parser.parse_args()

def notify(title, *msg):
    try:
        sp.run(['notify-send', title, '\n'.join(msg)])
    except:
        pass

def main():
    opts, args = parse_arguments()
    try:
        with open(HIST, 'r') as fp:
            hist = [i.strip() for i in fp.readlines() if i][::-1]
        uniq_hist = list()
        for i in hist:
            if i not in uniq_hist:
                uniq_hist.append(i)
        hist = uniq_hist
    except FileNotFoundError:
        hist = list()
    hist_len = len(hist)
    height = str(hist_len) if hist_len <= 10 else '10'

    if opts.dmenu:
        if opts.history and hist:
            query = run('dmenu', hist, [
                '-c', '-l', height, '-p', 'search:'
            ])[-1]
        else:
            query = run('dmenu', [], ['-c', '-p', 'search:'])[-1]
    else:
        if hist:
            query = run('fzf', hist, [
                '--height', height, '--prompt', 'search: ',
                '--print-query'
            ])[-1]
        else:
            query = input('search: ').strip()

    with open(HIST, 'a') as fp:
        fp.write(query + '\n')

    youtube = googleapiclient.discovery.build(
        'youtube', 'v3', developerKey=API_KEY)

    # videoCategoryId='10', # Music
    request = youtube.search().list(
        q=query.replace(' ', '-'),
        type='video,playlist',
        part="id,snippet",
        safeSearch='none',
        videoDuration='long' if opts.long else 'any',
        maxResults=25
    )
    response = request.execute()

    videos = dict()
    for i in response['items']:
        title = unescape(i['snippet']['title'])
        if 'playlistId' in i['id']:
            _id = i['id']['playlistId']
        else:
            _id = i['id']['videoId']
        videos[title] = _id
    keys = list(videos.keys())

    if opts.random:
        output = [choice(keys)]
    elif opts.all:
        output = keys
    elif opts.dmenu:
        output = run('dmenu', keys, ['-c', '-i', '-l', '25'])
    else:
        output = run('fzf',   keys, ['-m', '--height', '25'])

    playlist = "/tmp/mpv.m3u"
    with open(playlist, "w") as fp:
        fp.write("#EXTM3U\n")
        for k in output:
            url = f'https://www.youtube.com/watch?v={videos[k]}'
            fp.write(f"#EXTINF:0, {k}\n{url}\n")

    mpv = socket.socket(socket.AF_UNIX)
    mpv.connect(SOCKET_PATH)
    cmd = {"command": ["loadlist", playlist]}
    mpv.send(json.dumps(cmd).encode('utf-8') + b'\n')
    notify('♫ Playing now...', output[0])


if __name__ == '__main__':
    main()
