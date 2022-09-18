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
        torrent_name = get_torrent_name(v)
        if len(torrent_name) > 50:
            torrent_name = torrent_name[:47] + '...'
        size = get_psize(int(v['totalLength']))
        print(f'{i:3}: [{v["status"]}] {torrent_name:50} {size:10}')
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


def add_torrent(torrent):
    options = {
        'force-save': 'false',
        'bt-save-metadata': 'true',
        'check-integrity': 'true'
    }
    if os.path.isfile(torrent):
        options.update({'rpc-save-upload-metadata': 'false'})
        with open(torrent, 'rb') as fp:
            gid = s.aria2.addTorrent(
                xmlrpc.client.Binary(fp.read()),
                [], options
            )
        mv(torrent, CACHE)
    else:
        gid = s.aria2.addUri([torrent], options)

    if os.path.exists(FIFO):
        with open(FIFO, 'w') as fifo:
            fifo.write(f'{gid}\n')


def list_torrents():
    torrents = sorted(get_all(), key=lambda x: x['status'])
    for i in torrents:
        size = int(i["totalLength"])
        completed_length = int(i["completedLength"])
        p = 0 if size == 0 else completed_length * 100 // size
        psize = get_psize(size)
        plen = get_psize(completed_length)
        torrent_name = get_torrent_name(i)
        if len(torrent_name) > 60:
            torrent_name = torrent_name[:57] + '...'
        status = i['status']
        if status == 'active':
            dlspeed = get_psize(int(i['downloadSpeed']))
            print('{}: [{:>3}% {:>10}/{:>10} {:>10}/s ({:2})] [{}] - {}'.format(
                i['gid'], p, plen, psize, dlspeed, i['numSeeders'],
                status, torrent_name[:60]
            ))
        else:
            print('{}: [{:>3}% {:>10}/{:>10}] [{}] - {}'.format(
                i['gid'], p, plen, psize, status, torrent_name[:60]
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
        torrent_name = get_torrent_name(torrent)
        if torrent['status'] == 'active':
            s.aria2.remove(gid)
        else:
            s.aria2.removeDownloadResult(gid)
        print(torrent_name, 'removed')


def remove_all(dont_ask=False, status=None):
    if dont_ask or yes():
        for torrent in get_all():
            if status and status != torrent['status']:
                continue
            gid = torrent['gid']
            torrent_name = get_torrent_name(torrent)
            if torrent['status'] == 'active':
                s.aria2.remove(gid)
                sleep(1)

            try:
                s.aria2.removeDownloadResult(gid)
                print(torrent_name, 'removed')
            except Exception as err:
                print(err)


def remove_metadata(dont_ask=False):
    if dont_ask or yes():
        torrents = s.aria2.tellStopped(0, 100)
        for i in torrents:
            torrent_name = get_torrent_name(i)
            if torrent_name.startswith('[METADATA]'):
                try:
                    s.aria2.removeDownloadResult(i['gid'])
                    print(torrent_name, 'removed')
                except Exception as err:
                    print(err)


def move_to_top():
    torrents = s.aria2.tellWaiting(0, 100)
    try:
        gid = get_gid(torrents)[0]
    except IndexError:
        return
    s.aria2.changePosition(gid, 0, 'POS_SET')


if __name__ == '__main__':
    if not os.path.exists(PIDFILE):
        sp.Popen([WATCH], shell=True,
                stdout=sp.DEVNULL, stderr=sp.DEVNULL)

    opts, args = parse_arguments()
    if opts.list:
        list_torrents()
    elif opts.remove:
        remove(opts.yes)
    elif opts.remove_all:
        remove_all(opts.yes, opts.status)
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
    elif opts.top:
        move_to_top()
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
