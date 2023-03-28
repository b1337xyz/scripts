#!/usr/bin/env python3
from optparse import OptionParser
from threading import Thread
from urllib.parse import unquote
import json  # noqa: F401
import os
import subprocess as sp
import sys
import traceback
import xmlrpc.client

FIFO = 'test.fifo'
PREVIEW = 'preview.fifo'
MAX_DOWNLOADS = 200

LABEL = '╢ a-p a-u a-t a-r c-r c-a ╟'
FZF_ARGS = [
    '-m', '--delimiter=:', '--with-nth=2',
    '--border=bottom', '--preview-window', 'up:50%,wrap',
    '--border-label', LABEL,
    '--padding', '0,0,2%',
    '--preview', f"printf '%s\\n' {{}} > {PREVIEW}; cat {PREVIEW}",
    f"--bind=alt-p:reload(printf '%s\\n' pause {{+}} > {FIFO}; cat {FIFO})",
    f"--bind=alt-u:reload(printf '%s\\n' unpause {{+}} > {FIFO}; cat {FIFO})",
    f"--bind=alt-t:reload(printf '%s\\n' top {{+}} > {FIFO}; cat {FIFO})",
    f"--bind=alt-r:reload(printf '%s\\n' remove {{+}} > {FIFO}; cat {FIFO})",
    f"--bind=ctrl-r:reload(printf '%s\\n' rremove {{+}} > {FIFO}; cat {FIFO})",
    # f"--bind=ctrl-p:reload(printf '%s\\n' purge {{}} > {FIFO}; cat {FIFO})",
    '--bind=ctrl-a:toggle-all'
]
RED = '\033[1;31m'
GRN = '\033[1;32m'
END = '\033[m'


def psize(size):
    psize = f"{size} B"
    for i in 'KMGTP':
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def parse_arguments():
    parser = OptionParser()
    parser.add_option('--port', type='int', default=6800)
    return parser.parse_args()


def get_name(data):
    try:
        return data['bittorrent']['info']['name']
    except KeyError:
        pass

    path = data['files'][0]['path']
    if path:
        return path.split('/')[-1]

    try:
        return unquote(data['files'][0]['uris'][0]['uri'].split('/')[-1])
    except Exception:
        return data['gid']


def fzf(args):
    if not args:
        return

    try:
        proc = sp.Popen(
            ["fzf"] + FZF_ARGS,
            stdin=sp.PIPE, stdout=sp.PIPE,
            universal_newlines=True
        )
        proc.communicate('\n'.join(args))
    except KeyboardInterrupt:
        pass


def get_all():
    waiting = session.aria2.tellWaiting(0, MAX_DOWNLOADS)
    stopped = session.aria2.tellStopped(0, MAX_DOWNLOADS)
    active = session.aria2.tellActive()
    return sorted([] + waiting + stopped + active,
                  key=lambda x: x['status'], reverse=True)


def preview_fifo():
    try:
        while True:
            with open(PREVIEW, 'r') as fifo:
                data = [i for i in fifo.read().split('\n') if i]

            if len(data) == 0:
                break

            gid = data[-1].split(':')[0]
            try:
                output = []
                info = session.aria2.tellStatus(gid)
                # output = '\n'.join([f'{k}, {v}' for k, v in info.items()])
                status = info['status']
                total = int(info["totalLength"])
                completed = int(info["completedLength"])
                uploaded = int(info['uploadLength'])
                dlspeed = int(info['downloadSpeed'])
                upspeed = int(info['uploadSpeed'])
                Dir = info['dir']
                seeders = None if 'numSeeders' not in info else \
                    int(info["numSeeders"])

                try:
                    error_code = info['errorCode']
                    error_msg = info['errorMessage']
                except Exception:
                    error_code = None

                ratio = 0 if completed == 0 else uploaded / completed
                p = 0 if total == 0 else completed * 100 // total
                bar_size = 40
                blocks = p * bar_size // 100
                blank = bar_size - blocks
                output = '\n'.join([
                    f'[{blocks * "#"}{blank * " "}] {p:>3}%',
                    f'Completed: {psize(completed)}',
                    f'Dir:       {Dir}',
                    f'Ratio:     {ratio:.1f}',
                    f'Seeders:   {seeders}',
                    f'Size:      {psize(total)}',
                    f'Speed:     {psize(dlspeed)}/{psize(upspeed)}',
                    f'Status:    {status}',
                    f'GID:       {info["gid"]}',
                    f'Error:     {error_code} - {error_msg}' if error_code else ''  # noqa: E501
                ])

            except Exception:
                _, exc_value, _ = sys.exc_info()
                output = '\n'.join(traceback.format_exception(exc_value))

            with open(PREVIEW, 'w') as fifo:
                fifo.write(output.strip())
    finally:
        try:
            os.remove(PREVIEW)
        except FileNotFoundError:
            pass


def reload():
    commands = {
        'pause': lambda gid: session.aria2.pause(gid),
        'unpause': lambda gid: session.aria2.unpause(gid),
        'top': lambda gid: session.aria2.changePosition(gid, 0, 'POS_SET'),
        'remove': lambda gid: session.aria2.remove(gid),
        'rremove': lambda gid: session.aria2.removeDownloadResult(gid),
        'purge': lambda _: session.aria2.purgeDownloadResult(),
    }
    try:
        while True:
            with open(FIFO, 'r') as fifo:
                data = [i for i in fifo.read().split('\n') if i]

            if len(data) == 0:
                break

            cmd = data[0]
            for i in data[1:]:
                gid = i.split(':')[0]
                try:
                    commands[cmd](gid)
                except Exception:
                    pass

            output = ['{}:{}'.format(i['gid'], get_name(i)) for i in get_all()]
            with open(FIFO, 'w') as fifo:
                fifo.write('\n'.join(output))
    finally:
        try:
            os.remove(FIFO)
        except FileNotFoundError:
            pass


def kill_fifo(file):
    if os.path.exists(file):
        with open(file, 'w') as fifo:
            fifo.write('')

        try:
            os.remove(file)
        except FileNotFoundError:
            pass


def main(args=[]):
    global session
    session = xmlrpc.client.ServerProxy(f'http://localhost:{opts.port}/rpc')
    try:
        session.system.listMethods()
    except ConnectionRefusedError as err:
        print(err)
        sys.exit(1)

    if not os.path.exists(FIFO):
        os.mkfifo(FIFO)
    if not os.path.exists(PREVIEW):
        os.mkfifo(PREVIEW)

    t = Thread(target=reload)
    t.start()
    t = Thread(target=preview_fifo)
    t.start()

    try:
        fzf(['{}:{}'.format(i['gid'], get_name(i)) for i in get_all()])
    finally:
        kill_fifo(FIFO)
        kill_fifo(PREVIEW)


if __name__ == '__main__':
    opts, args = parse_arguments()
    main(args)