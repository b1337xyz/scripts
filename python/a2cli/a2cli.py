#!/usr/bin/env python3
from utils import *
from time import sleep
from xmlrpc.client import ServerProxy, Binary, MultiCall
from collections import defaultdict
import json


def select(action, downloads):
    if USE_FZF:
        return [downloads[int(i.split(':')[0])]
                for i in fzf(prompt=action, args=[
                    f'{i}:{get_name(v)} [{v["status"]}]'
                    for i, v in enumerate(downloads)
                ])]

    while list_all(numbered=True):
        try:
            print('1 2 3...')
            return [downloads[int(i.strip()) - 1]
                    for i in input(f'{action}: ').split()]
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            exit(130)
    return []


def get_all():
    mc = MultiCall(server)
    mc.aria2.tellWaiting(0, MAX)
    mc.aria2.tellStopped(0, MAX)
    mc.aria2.tellActive()
    return [j for sub in mc() for j in sub]


def add_torrent(torrent, _dir=TEMP_DIR, verify=False, metadata_only=False,
                index=None):
    _dir = os.path.realpath(_dir)
    options = {
        'dir': _dir,
        'check-integrity': str(verify).lower(),
        'metadata-only': str(metadata_only).lower(),
        'bt-save-metadata': 'true',
    }
    if index:
        options.update({'select-file': index})

    print(json.dumps(options, indent=2), f'{torrent=}')
    if os.path.isfile(torrent):
        if os.path.getsize(torrent) < MAX_SIZE:
            with open(torrent, 'rb') as fp:
                try:
                    aria2.addTorrent(Binary(fp.read()), [], options)
                except Exception as err:
                    print(err)
        else:
            print('Too big')
            magnet = get_magnet(torrent)
            add_torrent(magnet, _dir, verify, metadata_only)
    else:
        aria2.addUri([torrent], options)


def get_perc(x):
    return int(x['completedLength']) / (int(x['totalLength']) + .01)


def get_ratio(x):
    return int(x['uploadLength']) / (int(x['completedLength']) + .01)


def list_all(clear=False, sort_by=None, reverse=False, only_status=None,
             numbered=False):
    downloads = get_all()
    if sort_by == 'downloaded':
        downloads = sorted(downloads, key=get_perc, reverse=reverse)
    elif sort_by == 'ratio':
        downloads = sorted(downloads, key=get_ratio, reverse=reverse)
    elif sort_by is not None:
        downloads = sorted(downloads, key=lambda x: x.get(sort_by))

    if USE_FZF:
        fzf([f':{v["status"]}:[{get_name(v)}' for v in downloads])
        return

    counter = defaultdict(int)
    cols, lines = os.get_terminal_size()
    output = []
    total_dlspeed, total_upspeed, total_dl, total_up = 0, 0, 0, 0
    for i, dl in enumerate(downloads, start=1):
        status = dl['status']

        if not only_status is None and status != only_status:
            continue

        counter[status] += 1
        size = int(dl["totalLength"])
        completed_length = int(dl["completedLength"])
        upload_length = int(dl['uploadLength'])
        total_dl += completed_length
        total_up += upload_length
        ratio = round(get_ratio(dl), 1)
        # plen = psize(completed_length)
        dlspeed = int(dl['downloadSpeed'])
        total_dlspeed += dlspeed
        upspeed = int(dl['uploadSpeed'])
        total_upspeed += upspeed
        name = get_name(dl)
        error_code = '' if status != 'error' else dl["errorCode"]
        icon = {
            'active': '\033[1;32mA \033[m',
            'error': f'\033[1;31m{error_code} \033[m',
            'paused': '\033[1;36mP \033[m',
            'complete': '\033[1;34mC \033[m',
            'waiting': '\033[1;33mW \033[m',
            'removed': '\033[1;35mR \033[m',
        }.get(status)

        if i >= lines:  # stop printing
            continue

        bar_size = 12
        p = completed_length * 100 // (1 if size == 0 else size)
        blocks = p * bar_size // 100
        blank = bar_size - blocks
        bar = f'[{blocks * "#"}{blank * " "}{p:>3}%]'

        out = '{}{}{}{} {} {} {:>8} [{}] {}'.format(
            f'{i}) ' if numbered else '',
            f"{dl['gid']}: " if SHOW_GID else '',
            icon,
            bar,
            f'{psize(dlspeed):>8}/s',
            f'{psize(upspeed):>8}/s',
            psize(size), ratio, name)

        if len(out) > cols:
            out = out[:cols - 3] + '...'
        output.append(out)

    if clear:
        print('\033[2J\033[1;1H')  # clear

    if not output:
        print('Nothing to see here...')
        return

    print('\n'.join(output))
    if not numbered:
        total = sum([counter[k] for k in counter])
        print(f'total: {total} ' + ' '.join([f'{k}: {counter[k]}'
                                             for k in counter]), end='\t')

        print('(DL: {:>8}/s UP: {:>8}/s)\t(TDL: {:>8} TUP: {:>8})'.format(
            psize(total_dlspeed), psize(total_upspeed),
            psize(total_dl), psize(total_up)
            ))

    return len(output) > 0


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
    for dl in downloads if downloads else select('remove', get_all()):
        name = get_name(dl)
        gid = dl['gid']
        if dl['status'] in ['active', 'waiting', 'paused']:
            try:
                aria2.remove(gid)
            except Exception:
                aria2.forceRemove(gid)
        else:
            aria2.removeDownloadResult(gid)

        print(gid, name, 'removed')
        path = os.path.join(dl['dir'], name)
        if os.path.exists(path):
            print('Remove', path)
            sp.run(['rm', '-rvI', path])

    for dl in aria2.tellStopped(0, MAX):
        if dl['status'] == 'removed':
            aria2.removeDownloadResult(dl['gid'])
            print(gid, name, 'removed')


def remove_all(status=None):
    if not yes(args.yes):
        return

    remove([i for i in get_all() if status is None or status == i['status']])


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


def connect(host='127.0.0.1', port=6800):
    port = os.getenv('A2C_PORT', port)
    print('port:', port)
    return ServerProxy(f'http://{host}:{port}/rpc')


if __name__ == '__main__':
    args = parse_arguments()
    assert args.sort_by is None or args.sort_by in SORTING_KEYS
    server = connect(port=args.port)
    aria2 = server.aria2

    SHOW_GID = args.show_gid
    USE_FZF = args.fzf

    if args.list:
        list_all(False, args.sort_by, args.reverse, args.status)
    elif args.remove:
        remove()
    elif args.remove_all:
        remove_all(args.status)
        print(aria2.purgeDownloadResult())
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
        print(aria2.purgeDownloadResult())
    elif args.seed_time:
        print(aria2.changeGlobalOption({'seed-time': float(args.seed_time)}))
    elif args.seed_ratio:
        print(aria2.changeGlobalOption({'seed-ratio': float(args.seed_ratio)}))
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
        for arg in map(str.strip, args.argv):
            if arg.startswith('magnet:?'):
                add_torrent(arg, args.dir, args.check, args.metadata_only,
                            args.index)
            elif os.path.isfile(arg):
                file = os.path.realpath(arg)
                if is_torrent(file):
                    add_torrent(arg, args.dir, args.check, args.metadata_only,
                                args.index)
                elif file.endswith('.magnet'):
                    with open(file, 'r') as fp:
                        magnet = fp.readline().strip()
                    add_torrent(magnet, args.dir, args.check, args.metadata_only,
                                args.index)
            elif is_uri(arg):
                aria2.addUri([arg], {'dir': DL_DIR})
            else:
                print(f'Unrecognized URI: {arg}')
    elif args.watch:
        try:
            while True:
                list_all(True, args.sort_by, args.reverse, args.status)
                sleep(3)
        except KeyboardInterrupt:
            pass
    else:
        try:
            list_all(False, args.sort_by, args.reverse, args.status)
        except Exception as err:
            print(err)
