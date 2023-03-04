#!/usr/bin/env python3
from utils import *
from time import sleep
import json
import sys
import xmlrpc.client


def select(downloads):
    if not downloads:
        return []
    if len(downloads) == 1:
        return downloads

    if USE_FZF:
        return [
            downloads[int(i.split(':')[0])]
            for i in fzf([
                f'{i}:{get_name(v)} [{v["status"]}]'
                for i, v in enumerate(downloads)
            ])
        ]

    for i, v in enumerate(downloads):
        name = get_name(v)
        max_len = 80
        if len(name) > max_len:
            name = name[:max_len - 3] + '...'
        size = get_psize(int(v['totalLength']))
        print(f'{i:3}: [{v["status"]}] {name} {size:10}')

    while True:
        try:
            selected = [
                downloads[int(i.strip())]
                for i in input(': ').split()
            ]
            break
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            print('\nbye')
            sys.exit(0)
    return selected


def get_all():
    waiting = s.aria2.tellWaiting(0, MAX)
    stopped = s.aria2.tellStopped(0, MAX)
    active = s.aria2.tellActive()
    return sorted([] + waiting + stopped + active,
                  key=lambda x: x['status'], reverse=True)


def add_torrent(torrent):
    options = {
        'dir': TEMP_DIR,
        'force-save': 'false',
        'bt-save-metadata': 'true',
        'check-integrity': 'true'
    }
    if os.path.isfile(torrent):
        if os.path.getsize(torrent) < MAX_SIZE:
            with open(torrent, 'rb') as fp:
                try:
                    s.aria2.addTorrent(
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
        s.aria2.addUri([torrent], options)


def list_all():
    for i in get_all():
        size = int(i["totalLength"])
        completed_length = int(i["completedLength"])
        p = 0 if size == 0 else completed_length * 100 // size
        psize = get_psize(size)
        plen = get_psize(completed_length)
        name = get_name(i)
        max_len = 80
        if len(name) > max_len:
            name = name[:max_len - 3] + '...'
        status = i['status']
        gid = i['gid']
        if status == 'active':
            dlspeed = get_psize(int(i['downloadSpeed']))
            # seeders = i['numSeeders']
            print('{}[{:>3}% {:>10}/{:>10} {:>10}/s] [{}] - {}'.format(
                f'{gid}: ' if SHOW_GID else '', p, plen, psize, dlspeed,
                status, name
            ))
        else:
            print('{}[{:>3}% {:>10}/{:>10}] [{}] - {}'.format(
                f'{gid}: ' if SHOW_GID else '', p, plen, psize,
                status, name
            ))


def pause():
    downloads = s.aria2.tellActive()
    for dl in select(downloads):
        s.aria2.pause(dl['gid'])


def unpause():
    downloads = s.aria2.tellWaiting(0, MAX)
    for dl in select(downloads):
        s.aria2.unpause(dl['gid'])


def remove(downloads=[]):
    if not downloads:
        downloads = select(get_all())

    for dl in downloads:
        name = get_name(dl)
        gid = dl['gid']
        if dl['status'] in ['active', 'waiting']:
            try:
                s.aria2.remove(gid)
            except Exception as err:
                print(err)
                s.aria2.forceRemove(gid)
        else:
            try:
                s.aria2.removeDownloadResult(gid)
            except Exception as err:
                print(err)
                s.aria2.forceRemove(gid)

        print(name, 'removed')


def remove_all(dont_ask=False, status=None):
    if dont_ask or yes():
        for i in get_all():
            if status and status != i['status']:
                continue
            remove([i])


def remove_metadata(status=None):
    for dl in s.aria2.tellStopped(0, MAX):
        if status and status != dl['status']:
            continue
        name = get_name(dl)
        gid = dl['gid']
        if name.startswith('[METADATA]'):
            try:
                s.aria2.removeDownloadResult(gid)
                print(name, 'removed')
            except Exception as err:
                print(err)


def move_to_top():
    downloads = s.aria2.tellWaiting(0, MAX)
    try:
        gid = select(downloads)[0]['gid']
    except IndexError:
        return
    s.aria2.changePosition(gid, 0, 'POS_SET')


if __name__ == '__main__':
    opts, args = parse_arguments()

    s = xmlrpc.client.ServerProxy(f'http://localhost:{opts.port}/rpc')

    USE_FZF = opts.fzf
    SHOW_GID = opts.show_gid

    if opts.list:
        list_all()
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
        remove_metadata(opts.status)
    elif opts.top:
        move_to_top()
    elif opts.seed:
        print(s.aria2.changeGlobalOption({'seed-time': '0.0'}))
    elif opts.max_downloads:
        print(s.aria2.changeGlobalOption({
            'max-concurrent-downloads': str(opts.max_downloads)
        }))
    elif opts.download_limit:
        print(s.aria2.changeGlobalOption({
            'max-overall-download-limit': opts.download_limit
        }))
    elif opts.upload_limit:
        print(s.aria2.changeGlobalOption({
            'max-overall-upload-limit': opts.download_limit
        }))
    elif opts.list_gids:
        print('\n'.join([i['gid'] for i in get_all()]))
    elif args:
        for arg in args:
            if arg.startswith('magnet:?'):
                add_torrent(arg)
            elif os.path.isfile(arg):
                file = os.path.realpath(arg)
                if is_torrent(file):
                    add_torrent(file)
                elif file.endswith('.magnet'):
                    with open(arg, 'r') as fp:
                        magnet = fp.readline().strip()
                    add_torrent(magnet)
            elif is_uri(arg):
                s.aria2.addUri([arg], {'dir': DL_DIR})
            else:
                print(f'Unrecognized URI: {arg}')
    elif opts.watch:
        try:
            while True:
                os.system('clear')
                list_all()
                sleep(5)
        except KeyboardInterrupt:
            pass
    else:
        list_all()
