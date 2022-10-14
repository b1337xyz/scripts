#!/usr/bin/env python3
from utils import *
from threading import Thread
from random import random
import xmlrpc.client
import sys

s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')


def get_info(gid):
    att = 0
    while att < 15:
        try:
            return s.aria2.tellStatus(gid)
        except Exception as err:
            logging.error(f'{gid}: {err} attempt: {att}')
        sleep(random() * 5)
        att += 1


def watch(gid):
    global killed
    torrent = get_info(gid)
    torrent_name = get_torrent_name(torrent)
    logging.info(f'torrent added {torrent_name}')
    if torrent_name.startswith('[METADATA]'):
        notify('Saving the metadata...', torrent_name)
        while True:
            torrent = get_info(gid)
            if torrent['status'] == 'complete':
                break
            elif torrent['status'] == 'error' or killed:
                return
            sleep(5)

        new_gid = torrent["followedBy"][-1]
        gid = new_gid
        file = os.path.join(torrent['dir'],
            torrent['infoHash'] + '.torrent')
        if os.path.exists(file):
            mv(file, CACHE)

        try:
            s.aria2.removeDownloadResult(torrent['gid'])
        except:
            pass

    torrent = get_info(gid)
    torrent_name = get_torrent_name(torrent)
    size = get_psize(int(torrent["totalLength"]))
    status = torrent['status']
    notify(f"torrent started [{status}]",
            torrent_name, f'Size: {size}')
    logging.info(f'watching {torrent_name} [{status}]')
    while status not in ['complete', 'error']:
        if killed:
            return
        sleep(15)
        torrent = get_info(gid)
        status = torrent['status']

    notify(f"torrent finished [{status}]",
            torrent_name, f'Size: {size}')
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
    try:
        os.kill(int(open(PIDFILE, 'r').read()), 15)
    except:
        pass
    pid = os.getpid()
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

        os.remove(FIFO)
        for t in threads:
            t.join()


if __name__ == '__main__':
    main()
