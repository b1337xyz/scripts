#!/usr/bin/env python3
from utils import *
from time import sleep
from xmlrpc.client import ServerProxy, Binary, MultiCall
from collections import defaultdict
import json


def select(action, downloads):
    if len(downloads) < 2:
        return downloads

    if USE_FZF:
        return [downloads[int(i.split(':')[0])]
                for i in fzf(prompt=action, args=[
                    f'{i}:{get_name(v)} [{v["status"]}]'
                    for i, v in enumerate(downloads)
                ])]

    list_all(numbered=True)
    while True:
        try:
            print('1 2 3...')
            return [downloads[int(i.strip()) - 1]
                    for i in input(f'{action}: ').split()]
        except Exception as err:
            print(err)
        except KeyboardInterrupt:
            exit(130)


def get_all():
    mc = MultiCall(server)
    mc.aria2.tellWaiting(0, MAX)
    mc.aria2.tellStopped(0, MAX)
    mc.aria2.tellActive()
    return [j for sub in mc() for j in sub]


def add_torrent(torrent, _dir=TEMP_DIR, verify=False):
    options = {
        'dir': _dir,
        'force-save': 'false',
        'bt-save-metadata': 'false',
        'check-integrity': str(verify).lower()
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

        try:
            shutil.move(torrent, CACHE)
        except shutil.Error:
            pass
    else:
        options.update({'bt-save-metadata': 'true'})
        aria2.addUri([torrent], options)


def get_perc(x):
    return x['completedLength'] // (x['totalLength'] + .01)


def get_ratio(x):
    return x['uploadLength'] // (x['completedLength'] + .01)


def list_all(clear=False, sort_by=None, reverse=False, numbered=False):
    downloads = get_all()
    if not downloads:
        if clear:
            print('\033[2J\033[1;1H')  # clear
        print('Nothing to see here...')
        return

    if sort_by == 'downloaded':
        downloads = sorted(downloads, key=get_perc, reverse=reverse)
    elif sort_by == 'ratio':
        downloads = sorted(downloads, key=get_ratio, reverse=reverse)
    elif sort_by is not None:
        downloads = sorted(downloads, key=lambda x: x.get(sort_by))

    counter = defaultdict(int)
    cols, lines = os.get_terminal_size()
    cols += 7
    curr_line = 1
    output = []
    total_dlspeed = 0
    total_upspeed = 0
    for i, dl in enumerate(downloads, start=1):
        status = dl['status']
        counter[status] += 1

        if curr_line >= lines:  # stop printing
            continue
        curr_line += 1

        size = int(dl["totalLength"])
        completed_length = int(dl["completedLength"])
        # ratio = round(get_ratio(dl), 1)
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
        }[status]

        bar_size = 12
        p = int(completed_length * 100 // (size + .01))
        blocks = p * bar_size // 100
        blank = bar_size - blocks
        bar = f'[{blocks * "#"}{blank * " "} {p:>3}%]'

        out = '{}{}{}{} {} {:>8} {}'.format(
            f'{i}) ' if numbered else '',
            f"{dl['gid']}: " if SHOW_GID else '',
            icon, bar,
            f'{psize(dlspeed):>8}/s' if status == 'active' else ' ',
            psize(size), name)

        if len(out) > cols:
            out = out[:cols] + '...'
        output.append(out)

    if clear:
        print('\033[2J\033[1;1H')  # clear

    if not numbered:
        total = sum([counter[k] for k in counter])
        output.append(f'total: {total} ' + ' '.join([f'{k}: {counter[k]}'
                                                     for k in counter]))
    print('\n'.join(output))
    print('DL: {:>8}/s UP: {:>8}/s'.format(psize(total_dlspeed),
                                           psize(total_upspeed)))


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

    # 11  If aria2 was downloading same file at that moment.
    # 12  If aria2 was downloading same info hash torrent at that moment.
    # 13  If file already existed.
    for i in get_all():
        if i['status'] == 'error' and i.get('errorCode') in ['11', '13', '12']:
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
    assert args.sort_by is None or args.sort_by in SORTING_KEYS
    server = ServerProxy(f'http://127.0.0.1:{args.port}/rpc')
    aria2 = server.aria2

    SHOW_GID = args.show_gid
    USE_FZF = args.fzf

    if args.list:
        list_all(False, args.sort_by, args.reverse)
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
                add_torrent(arg, args.dir, args.check)
            elif os.path.isfile(arg):
                file = os.path.realpath(arg)
                if is_torrent(file):
                    add_torrent(file, args.dir, args.check)
                elif file.endswith('.magnet'):
                    with open(file, 'r') as fp:
                        magnet = fp.readline().strip()
                    add_torrent(magnet, args.dir, args.check)
                    os.remove(file)
            elif is_uri(arg):
                aria2.addUri([arg], {'dir': DL_DIR})
            else:
                print(f'Unrecognized URI: {arg}')
    elif args.watch:
        try:
            while True:
                list_all(True, args.sort_by, args.reverse)
                sleep(3)
        except KeyboardInterrupt:
            pass
    else:
        try:
            list_all(False, args.sort_by, args.reverse)
        except Exception as err:
            print(err)
