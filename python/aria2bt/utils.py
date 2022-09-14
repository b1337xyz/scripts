#!/usr/bin/env python3
from time import sleep
import subprocess as sp
import shutil
import logging
import os


HOME = os.getenv('HOME')
DL_DIR = os.path.join(HOME, 'Downloads')
CACHE = os.path.join(HOME, '.cache/torrents')
ROOT = os.path.dirname(os.path.realpath(__file__))
LOG  = os.path.join(ROOT, 'log')
FIFO = '/tmp/aria2bt.fifo'


logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='a',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%d-%m-%Y %H:%M:%S',
)


def parse_arguments():
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option('-l', '--list',    action='store_true')
    parser.add_option('-r', '--remove',  action='store_true')
    parser.add_option('-p', '--pause',   action='store_true')
    parser.add_option('-u', '--unpause', action='store_true')
    parser.add_option('--recheck',       action='store_true')
    parser.add_option('--pause-all',     action='store_true')
    parser.add_option('--purge',         action='store_true')
    parser.add_option('--unpause-all',   action='store_true')
    parser.add_option('--remove-all',    action='store_true')
    parser.add_option('--remove-metadata',    action='store_true')
    parser.add_option('--gid', type='string')
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


def saving_metadata(s, gid):
    notify(gid, 'saving the metadata...')
    att = 0
    new_gid = None
    while not new_gid and att < 10:
        sleep(3)
        torrent = s.aria2.tellStatus(gid)
        try:
            new_gid = torrent["followedBy"][-1]
            break
        except (KeyError, IndexError):
            att += 1
    else:
        return
    s.aria2.removeDownloadResult(gid)
    file = os.path.join(torrent['dir'], torrent['infoHash'] + '.torrent')
    if os.path.exists(file):
        mv(file, CACHE)
    # logging.info(f'{gid} > {new_gid}: successfully saved the metadata')
    return new_gid
