#!/usr/bin/env python3
from utils import *
from threading import Thread
from random import random
import xmlrpc.client
import sys

s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def get_info(gid):
    att = 0
    while att < 10:
        try:
            return s.aria2.tellStatus(gid)
        except Exception as err:
            logging.error(f'{gid}: {err} attempt: {att}')
        sleep(random() * 5)
        att += 1


def watch(gid):
    global killed
    torrent = get_info(gid)
    try:
        torrent_name = torrent['bittorrent']['info']['name']
    except KeyError:
        return
    size = get_psize(int(torrent["totalLength"]))
    status = torrent['status']
    notify(f"torrent started [{status}]", torrent_name, f'Size: {size}')
    logging.info(f'watching {torrent_name} [{status}]')
    while status not in ['complete', 'error']:
        if killed:
            return
        torrent = get_info(gid)
        try:
            status = torrent['status']
        except TypeError:
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


def main():
    global killed
    pid = os.getpid()
    if os.path.exists(PIDFILE):
        os.kill(int(open(PIDFILE, 'r').read()), 15)
    open(PIDFILE, 'w').write(str(pid))

    if not os.path.exists(FIFO):
        os.mkfifo(FIFO)
    killed = False
    threads = list()
    try:
        while True:
            with open(FIFO, 'r') as fifo:
                data = fifo.read()
                if len(data) == 0:
                    break
                for gid in [i for i in data.split('\n') if i]:
                    t = Thread(target=watch, args=(gid,))
                    t.start()
                    threads.append(t)
            for i, t in enumerate(threads):
                if not t.is_alive():
                    del threads[i]
    except KeyboardInterrupt:
        print('\nbye\n')
    finally:
        killed = True
        try:
            if int(open(PIDFILE, 'r').read()) == pid:
                os.remove(PIDFILE)
        except:
            pass

        try:
            os.remove(FIFO)
        except:
            pass

        for t in threads:
            t.join()


if __name__ == '__main__':
    main()

