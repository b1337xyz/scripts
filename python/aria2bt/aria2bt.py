#!/usr/bin/env python3
from utils import *
import json
import sys
import xmlrpc.client

s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def get_gid(torrents):
    if not torrents:
        return
    for i, v in enumerate(torrents):
        torrent_name = get_torrent_name(v['gid'])
        if len(torrent_name) > 50:
            torrent_name = torrent_name[:47] + '...'
        size = get_psize(int(v['totalLength']))
        print(f'{i:3}: {torrent_name:50} {size:10} [{v["status"]}]')
    while True:
        try:
            gids = [
                torrents[int(i.strip())]['gid']
                for i in input(': ').split()
            ]
            break
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            print('bye')
            sys.exit(0)
    return gids


def get_all():
    waiting = s.aria2.tellWaiting(0, 100)
    stopped = s.aria2.tellStopped(0, 100)
    active  = s.aria2.tellActive()
    return [] + waiting + stopped + active


def get_torrent_name(gid):
    torrent = s.aria2.tellStatus(gid)
    try:
        return torrent['bittorrent']['info']['name']
    except KeyError:
        return torrent['files'][0]['path']


def add_torrent(torrent):
    options = {
        'force-save': 'false',
        'bt-save-metadata': 'true',
    }
    if os.path.isfile(torrent):
        with open(torrent, 'rb') as fp:
            gid = s.aria2.addTorrent(
                xmlrpc.client.Binary(fp.read()),
                [], options
            )
        mv(torrent, CACHE)
    else:
        gid = s.aria2.addUri([torrent], options)
    with open(FIFO, 'w') as fifo:
        fifo.write(f'{gid}\n')
        fifo.flush()


def list_torrents():
    for i in get_all():
        size = int(i["totalLength"])
        completed_length = int(i["completedLength"])
        p = 0 if size == 0 else completed_length * 100 // size
        psize = get_psize(size)
        plen = get_psize(completed_length)
        torrent_name = get_torrent_name(i['gid'])
        if len(torrent_name) > 40:
            torrent_name = torrent_name[:37] + '...'
        status = i['status']
        if status == 'active':
            dlspeed = get_psize(int(i['downloadSpeed']))
            upspeed = get_psize(int(i['uploadSpeed']))
            print('{}: [{:>3}% {:10}/{:>10}] [{:>3} {:10}/{:>10}] [{}] - {}'.format(
                i['gid'], p, plen, psize, i['numSeeders'], dlspeed, upspeed,
                i['status'], torrent_name[:50]
            ))
        else:
            print('{}: [{:>3}% {:10}/{:>10}] [{}] - {}'.format(
                i['gid'], p, plen, psize, i['status'], torrent_name[:50]
            ))


def pause():
    torrents = s.aria2.tellActive()
    if torrents:
        for gid in get_gid(torrents):
            s.aria2.pause(gid)


def unpause():
    torrents = s.aria2.tellWaiting(0, 100)
    for gid in get_gid(torrents):
        s.aria2.unpause(gid)


def remove():
    torrents = get_all()
    for gid in get_gid(torrents):
        torrent = s.aria2.tellStatus(gid)
        torrent_name = get_torrent_name(gid)
        if torrent['status'] == 'active':
            s.aria2.remove(gid)
        else:
            s.aria2.removeDownloadResult(gid)
        print(torrent_name, 'removed')


def remove_all():
    if yes():
        for torrent in get_all():
            gid = torrent['gid']
            torrent_name = get_torrent_name(gid)
            try:
                s.aria2.removeDownloadResult(gid)
                print(torrent_name, 'removed')
            except Exception as err:
                print(err)


def remove_metadata():
    if yes():
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
    opts, args = parse_arguments()
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
