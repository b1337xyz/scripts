#!/usr/bin/env python3
from optparse import OptionParser
from time import sleep
import json
import os
import shutil
import subprocess as sp
import xmlrpc.client

### IMPORTANT!!! 
# See ../shell/autostart/aria2rpc.sh

HOME = os.getenv('HOME')
CACHE = os.path.join(HOME, '.cache/torrents')
DL_DIR = os.path.join(HOME, 'Downloads')


parser = OptionParser()
parser.add_option('-l', '--list',    action='store_true')
parser.add_option('-r', '--remove',  action='store_true')
parser.add_option('-p', '--pause',   action='store_true')
parser.add_option('-u', '--unpause', action='store_true')
parser.add_option('--pause-all',     action='store_true')
parser.add_option('--purge',         action='store_true')
parser.add_option('--unpause-all',   action='store_true')
parser.add_option('--remove-all',    action='store_true')
parser.add_option('--remove-metadata',    action='store_true')
parser.add_option('--gid', type='string')
opts, args = parser.parse_args()
s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def notify(title, *args):
    sp.run(['notify-send', '-i', 'emblem-downloads', title, '\n'.join(args)])


def is_torrent(file):
    out = sp.run(['file', '-Lbi', file], stdout=sp.PIPE).stdout.decode()
    return 'bittorrent' in out or 'octet-stream' in out


def get_psize(size):
    units = ["KB", "MB", "GB", "TB", "PB"]
    psize = f"{size} B"
    for i in units:
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:4.2f} {i}"
    return psize


def get_gid(torrents):
    for i, v in enumerate(torrents):
        torrent_name = get_torrent_name(v['gid'])
        if len(torrent_name) > 50:
            torrent_name = torrent_name[:47] + '...'
        size = get_psize(int(v['totalLength']))
        print(f'{i:3}: {torrent_name:50} {size:10} [{v["status"]}]')
    while True:
        try:
            i = int(input(': '))
            return torrents[i]['gid']
        except Exception as err:
            print(err)


def get_all():
    waiting = s.aria2.tellWaiting(0, 100)
    stopped = s.aria2.tellStopped(0, 100)
    active  = s.aria2.tellActive()
    return waiting + stopped + active


def get_torrent_name(gid):
    torrent = s.aria2.tellStatus(gid)
    try:
        return torrent['bittorrent']['info']['name']
    except KeyError:
        return torrent['files'][0]['path']


def watch(gid, torrent_name):
    if torrent_name.startswith('[METADATA]'):
        att = 0
        new_gid = None
        while not new_gid:
            torrent = s.aria2.tellStatus(gid)
            torrent_file = os.path.join(torrent['dir'], torrent['infoHash'] + '.torrent')
            try:
                new_gid = torrent["followedBy"][-1]
                gid = new_gid
                break
            except (KeyError, IndexError):
                pass
            sleep(1)
            att += 1
            if att > 10:
                return
        if os.path.exists(torrent_file):
            shutil.move(torrent_file, CACHE)

    torrent = s.aria2.tellStatus(gid)
    torrent_name = get_torrent_name(gid)
    size = get_psize(int(torrent["totalLength"]))
    status = torrent['status']
    notify(f"torrent started [{status}]", torrent_name, f'Size: {size}')
    while status in ['active', 'paused']:
        torrent = s.aria2.tellStatus(gid)
        status = torrent['status']
        sleep(15)
    notify(f"torrent finished [{status}]", torrent_name, f'Size: {size}')

    if status == 'complete':
        path = os.path.join(torrent['dir'], torrent_name)
        if os.path.exists(path):
            s.aria2.removeDownloadResult(gid)
            shutil.move(path, DL_DIR)


def add_torrent(torrent):
    options = {
        'force-save': 'false',
        'bt-save-metadata': 'true',
    }
    if os.path.isfile(torrent):
        shutil.move(torrent, CACHE)
        with open(torrent, 'rb') as fp:
            gid = s.aria2.addTorrent(
                xmlrpc.client.Binary(fp.read()),
                [], options
            )
    else:
        gid = s.aria2.addUri([torrent], options)
    torrent_name = get_torrent_name(gid)
    notify('torrent added', torrent_name)
    watch(gid, torrent_name)


def list_torrents():
    for i in get_all():
        size = int(i["totalLength"])
        psize = get_psize(size)
        torrent_name = get_torrent_name(i['gid'])
        if len(torrent_name) > 50:
            torrent_name = torrent_name[:47] + '...'
        status = i['status']
        if status == 'active':
            dlspeed = get_psize(int(i['downloadSpeed']))
            upspeed = get_psize(int(i['uploadSpeed']))
            print('{}: {:50} {:10} [{:8}] [{:10}/{:10}] ({})'.format(
                i['gid'], torrent_name, psize, i['status'], dlspeed, upspeed,
                i['numSeeders']
            ))
        else:
            print('{}: {:50} {:10} [{:8}]'.format(
                i['gid'], torrent_name, psize, i['status']
            ))


def pause():
    torrents = s.aria2.tellActive()
    if torrents:
        gid = get_gid(torrents)
        s.aria2.pause(gid)


def unpause():
    torrents = s.aria2.tellWaiting(0, 100)
    if torrents:
        gid = get_gid(torrents)
        s.aria2.pause(gid)


def remove():
    torrents = get_all()
    if torrents:
        gid = get_gid(torrents)
        torrent = s.aria2.tellStatus(gid)
        if torrent['status'] == 'active':
            s.aria2.remove(gid)
        else:
            s.aria2.removeDownloadResult(gid)


def remove_all():
    if input('Are you sure? [y/N] ').strip().lower() == 'y':
        for torrent in get_all():
            gid = torrent['gid']
            torrent_name = get_torrent_name(gid)
            try:
                s.aria2.removeDownloadResult(gid)
                print(torrent_name, 'removed')
            except Exception as err:
                print(err)


def remove_metadata():
    if input('Are you sure? [y/N] ').strip().lower() == 'y':
        torrents = s.aria2.tellStopped(0, 100)
        for i in torrents:
            torrent_name = get_torrent_name(i['gid'])
            if torrent_name.startswith('[METADATA]'):
                try:
                    s.aria2.removeDownloadResult(i['gid'])
                    print(torrent_name, 'removed')
                except Exception as err:
                    print(err)


def purge():
    pass


if __name__ == '__main__':
    if opts.list:
        list_torrents()
    elif opts.remove:
        remove()
    elif opts.remove_all:
        remove_all()
    elif opts.pause:
        pause()
    elif opts.unpause:
        unpause()
    elif opts.pause_all:
        s.aria2.pauseAll()
    elif opts.unpause_all:
        s.aria2.unpauseAll()
    elif opts.gid:
        print(json.dumps(s.aria2.tellStatus(opts.gid), indent=2))
    elif opts.remove_metadata:
        remove_metadata()
    elif opts.purge:
        purge()
    elif args:
        for arg in args:
            if os.path.isfile(arg):
                file = os.path.realpath(arg)
                if is_torrent(file):
                    add_torrent(file)
            elif 'magnet:' in arg:
                add_torrent(arg)
    else:
        list_torrents()
