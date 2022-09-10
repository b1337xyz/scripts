#!/usr/bin/env python3
from utils import *
from threading import Thread
from select import select
import xmlrpc.client
import sys

s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def get_torrent_name(gid):
    torrent = s.aria2.tellStatus(gid)
    try:
        return torrent['bittorrent']['info']['name']
    except KeyError:
        return torrent['files'][0]['path']


def watch(gid):
    global killed
    torrent_name = get_torrent_name(gid)
    if not torrent_name:
        return

    if torrent_name.startswith('[METADATA]'):
        att = 0
        new_gid = None
        while not new_gid:
            if killed:
                return
            torrent = s.aria2.tellStatus(gid)
            try:
                new_gid = torrent["followedBy"][-1]
                gid = new_gid
                break
            except (KeyError, IndexError):
                pass
            sleep(5)
            att += 1
            if att > 10:
                return
        torrent_file = os.path.join(torrent['dir'], torrent['infoHash'] + '.torrent')
        if os.path.exists(torrent_file):
            mv(torrent_file, CACHE)

    torrent = s.aria2.tellStatus(gid)
    torrent_name = get_torrent_name(gid)
    size = get_psize(int(torrent["totalLength"]))
    status = torrent['status']
    notify(f"torrent started [{status}]", torrent_name, f'Size: {size}')
    logging.info(f'watching {torrent_name} [{status}]')
    att = 0
    while status in ['active']:
        if killed:
            return
        if att > 3:
            return
        try:
            torrent = s.aria2.tellStatus(gid)
            status = torrent['status']
        except KeyboardInterrupt:
            return
        except Exception as err:
            logging.error(f'{gid}: {err}')
            att += 1
        sleep(15)
    notify(f"torrent finished [{status}]", torrent_name, f'Size: {size}')

    if status == 'complete':
        path = os.path.join(torrent['dir'], torrent_name)
        if os.path.exists(path):
            mv(path, DL_DIR)
        try:
            s.aria2.removeDownloadResult(gid)
        except:
            pass


if __name__ == '__main__':
    killed = False
    threads = list()
    if not os.path.exists(FIFO):
        os.mkfifo(FIFO)

    try:
        with open(FIFO, 'r') as fifo:
            while True:
                select([fifo], [], [fifo])
                gid = fifo.read()
                t = Thread(target=watch, args=(gid.strip(),))
                t.start()
                threads.append(t)
                for i, t in enumerate(threads):
                    if not t.is_alive():
                        del threads[i]
                sleep(5)
    except KeyboardInterrupt:
        print('\nbye\n')
    finally:
        killed = True
        if os.path.exists(FIFO):
            os.remove(FIFO)
        for t in threads:
            t.join()
