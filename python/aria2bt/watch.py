#!/usr/bin/env python3
from utils import *
from time import sleep
from threading import Thread
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
    torrent_name = get_torrent_name(gid)
    notify('torrent added', torrent_name)
    if torrent_name.startswith('[METADATA]'):
        att = 0
        new_gid = None
        while not new_gid:
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
    att = 0
    while status not in ['complete', 'error']:
        try:
            torrent = s.aria2.tellStatus(gid)
            status = torrent['status']
        except Exception as err:
            logging.error(f'{gid}: {err}')
            att += 1
        if att > 3:
            return
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
    threads = list()
    try:
        waiting = s.aria2.tellWaiting(0, 100)
        stopped = s.aria2.tellStopped(0, 100)
        active  = s.aria2.tellActive()
        for torrent in waiting + stopped + active:
            if torrent['status'] not in ['complete', 'error']:
                gid = torrent['gid']
                t = Thread(target=watch, args=(gid,))
                t.start()
                threads.append(t)

        if not os.path.exists(FIFO):
            os.mkfifo(FIFO)
        with open(FIFO, 'r') as fifo:
            while True:
                gid = fifo.read()
                if gid:
                    logging.info(f'thread starded, {gid}, {len(threads)}')
                    t = Thread(target=watch, args=(gid.strip(),))
                    t.start()
                    threads.append(t)
                    for i, t in enuemerate(threads):
                        if not t.isalive():
                            del threads[i]
    finally:
        for t in threads:
            t.join()
