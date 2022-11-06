#!/usr/bin/env python3
from time import sleep
import subprocess as sp
import shutil
import logging
import os

HOME = os.getenv('HOME')
DL_DIR = os.path.join(HOME, 'Downloads')
TEMP_DIR = os.path.join(DL_DIR, '.torrents')
CACHE = os.path.join(HOME, '.cache/torrents')
ROOT = os.path.dirname(os.path.realpath(__file__))
LOG  = os.path.join(ROOT, 'log')
FIFO = '/tmp/aria2bt.fifo'
PIDFILE = '/tmp/aria2bt.pid'
WATCH = os.path.join(ROOT, 'watch.py')
MAX_SIZE = 2000 * 1000 # 2 MB
FZF_ARGS = [
    '-m',
]


logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='w',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%d-%m-%Y %H:%M:%S',
)


def parse_arguments():
    from optparse import OptionParser
    usage = 'Usage: %prog [options] [TORRENT_FILE | MAGNET]'
    parser = OptionParser(usage=usage)
    parser.add_option('--fzf', action='store_true')
    parser.add_option('-l', '--list',    action='store_true',
        help='list all torrents')
    parser.add_option('-r', '--remove',  action='store_true',
        help='remove chosen torrents')
    parser.add_option('-p', '--pause',   action='store_true',
        help='pause chosen torrents')
    parser.add_option('-u', '--unpause', action='store_true',
        help='unpause chosen torrents')
    parser.add_option('--pause-all',     action='store_true',
        help='pause all torrents')
    parser.add_option('--unpause-all',   action='store_true',
        help='unpause all torrents')
    parser.add_option('--remove-all',    action='store_true',
        help='remove all torrents')
    parser.add_option('--remove-metadata', action='store_true',
        help='remove torrents metadata')
    parser.add_option('--top', action='store_true',
        help='move a torrent to the top of the queue')
    parser.add_option('--status', type='string',
        help='active complete error paused removed waiting')
    parser.add_option('--gid', type='string',
        help='return a JSON of given GID')
    parser.add_option('--show-gid', action='store_true',
        help='show gid')
    parser.add_option('-y', '--yes', action='store_true',
        help='don\'t ask')

    return parser.parse_args()


def yes():
    return input('Are you sure? [y/N] ').strip().lower() in ['y', 'yes']


def mv(src, dst):
    logging.info(f"mv '{src}' > '{dst}'")
    try:
        shutil.move(src, dst)
    except Exception as err:
        logging.error(err)


def notify(title, *args):
    try:
        msg = '\n'.join(args)
        sp.run(['notify-send', '-i', 'emblem-downloads', title, msg])
    except Exception as err:
        logging.error(err)


def is_torrent(file):
    cmd = ['file', '-Lbi', file]
    out = sp.run(cmd, stdout=sp.PIPE).stdout.decode()
    return 'bittorrent' in out or 'octet-stream' in out


def get_psize(size):
    units = ["KB", "MB", "GB", "TB", "PB"]
    psize = f"{size} B"
    for i in units:
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def get_torrent_name(torrent):
    try:
        return torrent['bittorrent']['info']['name']
    except KeyError:
        return torrent['files'][0]['path']


def fzf(args):
    proc = sp.Popen(
       ["fzf"] + FZF_ARGS,
       stdin=sp.PIPE,
       stdout=sp.PIPE,
       universal_newlines=True
    )
    out = proc.communicate('\n'.join(args))
    if proc.returncode != 0:
        exit(proc.returncode)
    return [i for i in out[0].split('\n') if i]

