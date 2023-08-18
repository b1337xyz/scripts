#!/usr/bin/env python3
from urllib.parse import unquote
import subprocess as sp
import shutil
import os
import re

DL_DIR = os.path.expanduser('~/Downloads')
CACHE = os.path.expanduser('~/.cache/torrents')
TEMP_DIR = os.path.join(DL_DIR, '.torrents')
MAX = 999
MAX_SIZE = 2000000  # 2 MB
FZF_ARGS = [
    '-m', '--delimiter=:', '--with-nth=2',
    '--bind', 'ctrl-a:toggle-all',
]


def parse_arguments():
    from argparse import ArgumentParser
    usage = 'Usage: %(prog)s [options] [FILE | URI]'
    parser = ArgumentParser(usage=usage)
    parser.add_argument('-w', '--watch', action='store_true')
    parser.add_argument('--port', type=str, default='6800')
    parser.add_argument('-V', '--check-integrity', action='store_true',
                        dest='check', help='Check file integrity')
    parser.add_argument('-d', '--dir', type=str, default=TEMP_DIR,
                        help='directory to store the downloaded file \
                                (default: %(default)s)')
    parser.add_argument('-l', '--list', action='store_true',
                        help='list all downloads')
    parser.add_argument('-r', '--remove', action='store_true',
                        help='remove chosen download')
    parser.add_argument('-p', '--pause', action='store_true',
                        help='pause chosen download')
    parser.add_argument('-u', '--unpause', action='store_true',
                        help='unpause chosen download')
    parser.add_argument('--pause-all', action='store_true',
                        help='pause all downloads')
    parser.add_argument('--unpause-all', action='store_true',
                        help='unpause all downloads')
    parser.add_argument('--remove-all', action='store_true',
                        help='remove all downloads')
    parser.add_argument('--remove-metadata', action='store_true',
                        help='remove all METADATA')
    parser.add_argument('--top', action='store_true',
                        help='move a download to the top of the queue')
    parser.add_argument('--status', type=str,
                        help='active complete error paused removed waiting')
    parser.add_argument('--gid', type=str,
                        help='return a JSON of given GID')
    parser.add_argument('--show-gid', action='store_true',
                        help='show gid')
    parser.add_argument('--files', action='store_true',
                        help='list downloaded files from selected download')
    parser.add_argument('--seed', action='store_true',
                        help='sets seed-time=0.0')
    parser.add_argument('-m', '--max-downloads', type=int, metavar='[0-9]+',
                        help='max concurrent downloads')
    parser.add_argument('--download-limit', type=str, metavar='<SPEED>',
                        help='overall download speed limit')
    parser.add_argument('--upload-limit', type=str, metavar='<SPEED>',
                        help='overall upload speed limit')
    parser.add_argument('-y', '--yes', action='store_false',
                        help='don\'t ask')
    parser.add_argument('-s', '--save', action='store_true',
                        help='save torrent')
    parser.add_argument('--fzf', action='store_true', help='use fzf')
    parser.add_argument('--list-gids', action='store_true')
    parser.add_argument('--purge', action='store_true')
    parser.add_argument('--purge-all', action='store_true')
    parser.add_argument('argv', type=str, nargs='*',
                        help='[URI | MAGNET | TORRENT_FILE]')

    return parser.parse_args()


def yes(ask=True):
    if not ask:
        return True
    return input('Are you sure? [y/N] ').strip().lower() in ['y', 'yes']


def mv(src, dst):
    try:
        shutil.move(src, dst)
    except shutil.Error:
        pass


def notify(title, msg, icon='emblem-downloads'):
    try:
        sp.Popen(['notify-send', '-i', icon, title, msg])
    except Exception:
        pass


def is_uri(string: str) -> bool:
    return isinstance(re.match(r'\w+:(:?\/?\/?)[^\s]+', string), re.Match)


def is_torrent(file):
    cmd = ['file', '-Lbi', file]
    out = sp.run(cmd, stdout=sp.PIPE).stdout.decode()
    return 'bittorrent' in out or 'octet-stream' in out


def get_magnet(file):
    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    return re.search(r'magnet:\?[^\s]+', out).group(1)


def get_psize(size):
    psize = f"{size} B"
    for i in 'KMGTP':
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def get_name(info):
    try:
        return info['bittorrent']['info']['name']
    except KeyError:
        pass

    path = info['files'][0]['path']
    if path:
        return path.split('/')[-1]

    try:
        return unquote(info['files'][0]['uris'][0]['uri'].split('/')[-1])
    except Exception:
        return info['gid']


def fzf(prompt, args):
    if not args:
        return

    proc = sp.Popen(["fzf", '--prompt', f'{prompt}> '] + FZF_ARGS,
                    stdin=sp.PIPE, stdout=sp.PIPE,
                    universal_newlines=True)
    sel, _ = proc.communicate('\n'.join(args))
    return [i for i in sel.split('\n') if i]
