#!/usr/bin/env python3
from utils import *
from time import sleep
import json
import sys
from xmlrpc.client import ServerProxy, Binary


def select(action, downloads):
    if not downloads:
        return []

    if len(downloads) == 1:
        return downloads

    if USE_FZF:
        return [
            downloads[int(i.split(':')[0])]
            for i in fzf(prompt=action, args=[
                f'{i}:{get_name(v)} [{v["status"]}]'
                for i, v in enumerate(downloads)
            ])
        ]

    for i, v in enumerate(downloads):
        name = get_name(v)
        max_len = 70
        if len(name) > max_len:
            name = name[:max_len - 3] + '...'
        size = get_psize(int(v['totalLength']))
        print(f'{i:3}: [{v["status"]}] {name} {size:10}')

    while True:
        try:
            selected = [
                downloads[int(i.strip())]
                for i in input(f'{action}: ').split()
            ]
            break
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            sys.exit(130)
    return selected


def get_all():
    waiting = aria2.tellWaiting(0, MAX)
    stopped = aria2.tellStopped(0, MAX)
    active = aria2.tellActive()
    return active + waiting + stopped


def add_torrent(torrent):
    options = {
        'dir': TEMP_DIR,
        'force-save': 'false',
        'bt-save-metadata': 'true',
        'check-integrity': 'false'
    }
    if os.path.isfile(torrent):
        if os.path.getsize(torrent) < MAX_SIZE:
            with open(torrent, 'rb') as fp:
                try:
                    aria2.addTorrent(Binary(fp.read()), [], options)
                except Exception as err:
                    logging.error(err)
        else:
            magnet = get_magnet(torrent)
            add_torrent(magnet)

        shutil.move(torrent, CACHE)
    else:
        aria2.addUri([torrent], options)


def list_all():
    downloads = get_all()
    if not downloads:
        return

    counter = dict()
    lines = os.get_terminal_size().lines
    curr_line = 1
    for i in downloads:
        status = i['status']
        if status not in counter:
            counter[status] = 1
        else:
            counter[status] += 1

        if curr_line >= lines:  # stop printing
            continue
        curr_line += 1

        size = int(i["totalLength"])
        completed_length = int(i["completedLength"])
        p = 0 if size == 0 else completed_length * 100 // size
        psize = get_psize(size)
        # plen = get_psize(completed_length)
        name = get_name(i)
        max_len = 60
        if len(name) > max_len:
            name = name[:max_len - 3] + '...'

        error_code = '' if status != 'error' else i["errorCode"]
        icon = {
            'active': '\033[1;32mA \033[m',
            'error': f'\033[1;31m{error_code} \033[m',
            'paused': '\033[1;36mP \033[m',
            'complete': '\033[1;34mC \033[m',
            'waiting': '\033[1;33mW \033[m',
            'removed': '\033[1;35mR \033[m',
        }[status]

        if SHOW_GID:
            print(i['gid'], end=' ')

        bar_size = 12
        blocks = p * bar_size // 100
        blank = bar_size - blocks
        bar = f'{blocks * "#"}{blank * " "}'
        if status == 'active':
            dlspeed = get_psize(int(i['downloadSpeed']))
            # upspeed = get_psize(int(i['uploadSpeed']))
            print('{}[{} {:>3}%] {:>10}/s {:>10} - {}'.format(
                icon, bar, p, dlspeed, psize, name))
        else:
            print('{}[{} {:>3}%] {:>10} - {}'.format(
                icon, bar, p, psize, name))

    total = sum([counter[k] for k in counter])
    print(f'total: {total}', ' '.join([f'{k}: {counter[k]}' for k in counter]))


def pause():
    downloads = aria2.tellActive()
    for dl in select('pause', downloads):
        aria2.pause(dl['gid'])


def list_files():
    downloads = aria2.tellActive() + aria2.tellWaiting(0, MAX)
    try:
        dl = select('files', downloads)[0]
        output = []
        for f in aria2.tellStatus(dl['gid']).get('files', []):
            p = int(f['completedLength']) * 100 // int(f['length'])
            output.append((p, f['path']))

        print('\n'.join([
            f'{p}%\t{f}' for p, f in sorted(output, key=lambda x: x[0])
        ]))
    except IndexError:
        pass


def unpause():
    downloads = aria2.tellWaiting(0, MAX)
    for dl in select('unpause', downloads):
        aria2.unpause(dl['gid'])


def remove(downloads=[]):
    if not downloads:
        downloads = select('remove', get_all())

    for dl in downloads:
        name = get_name(dl)
        gid = dl['gid']
        if dl['status'] in ['active', 'waiting']:
            try:
                aria2.remove(gid)
            except Exception as err:
                print(err)
                aria2.forceRemove(gid)
        else:
            try:
                aria2.removeDownloadResult(gid)
            except Exception as err:
                print(err)
                aria2.forceRemove(gid)
        print(name, 'removed')


def remove_all(status=None):
    if not yes(args.yes):
        return

    remove([i for i in get_all() if status is None or status == i['status']])


def purge():
    if not yes(False):
        return

    # 11     If aria2 was downloading same file at that moment.
    # 13     If file already existed.
    for i in get_all():
        if i['status'] in 'error':
            if i['errorCode'] in ['11', '13']:
                remove([i])
        elif i['status'] in ['complete', 'removed']:
            remove([i])


def remove_metadata(status=None):
    for dl in aria2.tellStopped(0, MAX):
        if status and status != dl['status']:
            continue
        name = get_name(dl)
        gid = dl['gid']
        if name.startswith('[METADATA]'):
            try:
                aria2.removeDownloadResult(gid)
                print(name, 'removed')
            except Exception as err:
                print(err)


def move_to_top():
    downloads = aria2.tellWaiting(0, MAX)
    try:
        gid = select('move to top', downloads)[0]['gid']
    except IndexError:
        return
    aria2.changePosition(gid, 0, 'POS_SET')


if __name__ == '__main__':
    args = parse_arguments()

    aria2 = ServerProxy(f'http://localhost:{args.port}/rpc').aria2

    SHOW_GID = args.show_gid
    USE_FZF = args.fzf

    if args.list:
        list_all()
    elif args.remove:
        remove()
    elif args.remove_all:
        remove_all(args.status)
    elif args.pause:
        pause()
    elif args.unpause:
        unpause()
    elif args.pause_all:
        aria2.pauseAll()
    elif args.unpause_all:
        aria2.unpauseAll()
    elif args.gid:
        print(json.dumps(aria2.tellStatus(args.gid), indent=2))
    elif args.remove_metadata:
        remove_metadata(args.status)
    elif args.top:
        move_to_top()
    elif args.purge:
        purge()
    elif args.purge_all:
        print(aria2.purgeDownloadResult())
    elif args.seed:
        print(aria2.changeGlobalOption({'seed-time': '0.0'}))
    elif args.max_downloads:
        print(aria2.changeGlobalOption({
            'max-concurrent-downloads': str(args.max_downloads)
        }))
    elif args.download_limit:
        print(aria2.changeGlobalOption({
            'max-overall-download-limit': args.download_limit
        }))
    elif args.upload_limit:
        print(aria2.changeGlobalOption({
            'max-overall-upload-limit': args.download_limit
        }))
    elif args.list_gids:
        print('\n'.join([i['gid'] for i in get_all()]))
    elif args.files:
        list_files()
    elif args.argv:
        for arg in args.argv:
            if arg.startswith('magnet:?'):
                add_torrent(arg)
            elif os.path.isfile(arg):
                file = os.path.realpath(arg)
                if is_torrent(file):
                    add_torrent(file)
                elif file.endswith('.magnet'):
                    with open(file, 'r') as fp:
                        magnet = fp.readline().strip()
                    add_torrent(magnet)
                    os.remove(file)
            elif is_uri(arg):
                aria2.addUri([arg], {'dir': DL_DIR})
            else:
                print(f'Unrecognized URI: {arg}')
    elif args.watch:
        try:
            while True:
                print('\033[2J\033[1;1H')  # clear
                list_all()
                sleep(5)
        except KeyboardInterrupt:
            pass
    else:
        try:
            list_all()
        except Exception as err:
            print(err)
