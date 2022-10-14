#!/usr/bin/env python3
from utils import *
import json
import sys
import xmlrpc.client
import re

s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def get_torrents(torrents):
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
            torrents = [
                torrents[int(i.strip())]
                for i in input(': ').split()
            ]
            break
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            print('\nbye')
            sys.exit(0)
    return torrents

def get_magnet(file):
    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    return re.search(r'Magnet URI: (.*)', out).group(1)


def get_all():
    waiting = s.aria2.tellWaiting(0, 100)
    stopped = s.aria2.tellStopped(0, 100)
    active  = s.aria2.tellActive()
    return sorted([] + waiting + stopped + active, key=lambda x: x['status'], reverse=True)


def add_torrent(torrent):
    options = {
        'dir': TEMP_DIR,
        'force-save': 'false',
        'bt-save-metadata': 'true',
        'check-integrity': 'true'
    }
    if os.path.isfile(torrent):
        if os.path.getsize(torrent) < MAX_SIZE:
            options.update({'rpc-save-upload-metadata': 'false'})
            with open(torrent, 'rb') as fp:
                try:
                    gid = s.aria2.addTorrent(
                        xmlrpc.client.Binary(fp.read()),
                        [], options
                    )
                    mv(torrent, CACHE)
                except Exception as err:
                    logging.error(err)
        else:
            magnet = get_magnet(torrent)
            return add_torrent(magnet)
    else:
        gid = s.aria2.addUri([torrent], options)

    if os.path.exists(FIFO):
        with open(FIFO, 'w') as fifo:
            fifo.write(f'{gid}\n')


def list_torrents():
    for i in get_all():
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
    for torrent in get_torrents(torrents):
        s.aria2.pause(torrent['gid'])


def unpause():
    torrents = s.aria2.tellWaiting(0, 100)
    for torrent in get_torrents(torrents):
        s.aria2.unpause(torrent['gid'])


def remove(torrents=[]):
    if not torrents:
        torrents = get_torrents(get_all())

    for torrent in torrents:
        torrent_name = get_torrent_name(torrent)
        gid = torrent['gid']
        if torrent['status'] in ['active', 'waiting']:
            try:
                s.aria2.remove(gid)
            except Exception as err:
                print(err)
                s.aria2.forceRemove(gid)
        else:
            s.aria2.removeDownloadResult(gid)
        print(torrent_name, 'removed')


def remove_all(dont_ask=False, status=None):
    if dont_ask or yes():
        for i in get_all():
            if status and status != i['status']:
                continue
            remove([i])


def remove_metadata():
    torrents = s.aria2.tellStopped(0, 100)
    for torrent in torrents:
        torrent_name = get_torrent_name(torrent)
        gid = torrent['gid']
        if torrent_name.startswith('[METADATA]'):
            try:
                s.aria2.removeDownloadResult(gid)
                print(torrent_name, 'removed')
            except Exception as err:
                print(err)


def move_to_top():
    torrents = s.aria2.tellWaiting(0, 100)
    try:
        gid = get_torrents(torrents)[0]['gid']
    except IndexError:
        return
    s.aria2.changePosition(gid, 0, 'POS_SET')


if __name__ == '__main__':
    if not os.path.exists(PIDFILE):
        sp.Popen([WATCH], shell=True,
                stdout=sp.DEVNULL, stderr=sp.DEVNULL)
        sleep(1)

    opts, args = parse_arguments()
    if opts.list:
        list_torrents()
    elif opts.remove:
        remove()
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
