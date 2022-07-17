#!/usr/bin/env python3
from aiohttp import ClientSession
from asyncio.exceptions import InvalidStateError
from bs4 import BeautifulSoup as BS
from optparse import OptionParser
import aiofiles
import asyncio
import json
import os
import random
import re
import sys

# MAKE SURE YOU USE THE SAME IP AND USERAGENT AS WHEN YOU GOT YOUR COOKIE!
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.nhentai_history')
CONFIG = os.path.join(HOME, '.nhentai.json')
DL_DIR = os.path.join(HOME, 'Downloads/nhentai')
UA = None
COOKIE = None

DOMAIN = 'nhentai.net'
Q_SIZE = 4
bad = '\033[1;31m:(\033[m'
good = '\033[1;32m:)\033[m'


def parse_arguments():
    global parser
    usage = 'Usage: %prog [options] <url>'
    parser = OptionParser(usage=usage)
    parser.add_option(
        '-d', '--dir', dest='dl_dir', default=DL_DIR, metavar='DIR',
        help='download directory'
    )
    parser.add_option(
        '-i', '--input-file', dest='input_file', metavar='FILE',
        action='store', help='Download URLs found in FILE'
    )
    parser.add_option(
        '-c', '--cookie', dest='cookie', metavar="STR",
        help="csrftoken=TOKEN; sessionid=ID; cf_clearance=CLOUDFLARE"
    )
    parser.add_option('-u', '--user-agent', dest='user_agent', metavar="STR")
    parser.add_option('-a', '--artist', dest='artist', default=None)
    opts, args = parser.parse_args()
    if len(args) == 0 and not opts.input_file:
        parser.error('<url> not provided')
    assert os.path.isdir(opts.dl_dir), f'"{opts.dl_dir}" not a directory'
    return (opts, args)


def load_config(cookie=None, agent=None):
    try:
        with open(CONFIG , 'r') as fp:
            config = json.load(fp)
    except FileNotFoundError:
        config = dict()
    if cookie:
        config['cookie'] = cookie
    if agent:
        config['user-agent'] = agent
    if cookie or agent:
        with open(CONFIG, 'w') as fp:
            json.dump(config, fp, indent=2)
    return config


async def random_sleep():
    await asyncio.sleep(random.random() * .5)


async def download(session, dl_dir, queue):
    while True:
        url, fname = await queue.get()
        file = os.path.join(dl_dir, fname)
        if os.path.exists(file):
            queue.task_done()
            continue
        print(url)
        att = 1
        while True:
            async with session.get(url) as r:
                status = r.status
                if status != 200:
                    print(url, f'Status: {status} {bad} ({att})')
                    await random_sleep()
                    att += 1
                    continue
                else:
                    print(url, f'Status: {status} {good} ({att})')
                f = await aiofiles.open(file, mode='wb')
                await f.write(await r.read())
                await f.close()
            break
        proc = await asyncio.create_subprocess_exec(
            'aria2c', *['-S', file],
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL
        )
        stdout, stderr = await proc.communicate()
        torrent_name = re.search(r'[ \t]*1\|\./([^/]*)', stdout.decode())
        if torrent_name:
            torrent = os.path.join(dl_dir, torrent_name.group(1))
            if os.path.exists(torrent):
                os.remove(file)
        await random_sleep()
        queue.task_done()


async def get_posts(session, queue, posts=set()):
    while True:
        url = await queue.get()
        att = 1
        while True:
            async with session.get(url) as r:
                status = r.status
                if status != 200:
                    print(url, f'{status} {bad} ({att})')
                    await random_sleep()
                    att += 1
                    continue
                else:
                    print(url, f'{status} {good} ({att})')
                soup = BS(await r.text(), 'html.parser')
            break
        gallery = soup.findAll('div', {'class': 'gallery'})
        for div in gallery:
            if 'english' not in div.text.lower():
                continue
            posts.add(div.a.get('href'))
        await random_sleep()
        queue.task_done()
    return posts


async def parse_urls(urls):
    new_urls = []
    for url in urls:
        with open(HIST, 'a') as fp:
            fp.write(url + '\n')
        if 'page=' in url:
            url = re.sub(r'([\?&]page=)\d*', r'\1{}', url)
        elif '?' in url:
            url += '&page={}'
        else:
            url += '?page={}'
        new_urls.append(url)
    return new_urls


async def main(urls):
    cookies = {
        x.strip(): y.strip()
        for x, y in [i.split('=') for i in COOKIE.split(';')]
    }
    headers = {'user-agent': UA}
    async with ClientSession(cookies=cookies, headers=headers) as s:
        urls = await parse_urls(urls)
        queue = None
        for url in urls:
            del queue
            queue = asyncio.Queue()
            try:
                if '?q=' in url:
                    r = re.compile(r'\?q=([^&]*)')
                else:
                    r = re.compile(r'\.net/\w*/([^/\?$]*)')
                tag = r.search(url.strip()).group(1)
                dl_dir = os.path.join(opts.dl_dir, tag)
                if not os.path.exists(dl_dir):
                    os.mkdir(dl_dir)
            except AttributeError:
                dl_dir = opts.dl_dir

            # request the first page
            async with s.get(url.format(1)) as r:
                soup = BS(await r.text(), 'html.parser')
            posts = set()
            gallery = soup.findAll('div', {'class': 'gallery'})
            for div in gallery:
                if 'english' not in div.text.lower():
                    continue
                posts.add(div.a.get('href'))
            last_page = soup.find('a', {'class': 'last'})
            if last_page:
                last_page = int(last_page.get('href').split('=')[-1])
                for page in range(2, last_page+1):
                    queue.put_nowait(url.format(page))
                tasks = []
                q_size = last_page - 1 if last_page - 1 < Q_SIZE else Q_SIZE
                for _ in range(q_size):
                    tasks += [asyncio.create_task(get_posts(s, queue, posts))]
                await queue.join()
                for task in tasks:
                    task.cancel()
                    try:
                        posts.update(task.result())
                    except InvalidStateError:
                        pass
                # await asyncio.gather(*tasks, return_exceptions=True)

            print(f'Posts: {len(posts)}')
            if not posts:
                print('Nothing found')
                continue

            del queue
            queue = asyncio.Queue()
            for url in posts:
                url = f'https://{DOMAIN}{url}download'
                fname = url.split('/')[-2] + '.torrent'
                queue.put_nowait((url, fname))
            tasks = []
            q_size = len(posts) if len(posts) < Q_SIZE else Q_SIZE
            for i in range(q_size):
                tasks += [asyncio.create_task(
                    download(s, dl_dir, queue)
                )]
            await queue.join()
            for task in tasks:
                task.cancel()

            torrents = [
                os.path.join(dl_dir, i) for i in os.listdir(dl_dir)
                if i.endswith('.torrent')
            ]
            args = [
                '--dir', dl_dir, '--bt-stop-timeout=500',
                '--seed-time=0'
            ] + torrents
            proc = await asyncio.create_subprocess_exec('aria2c', *args)
            await proc.communicate()


if __name__ == '__main__':
    opts, args = parse_arguments()
    config = load_config(opts.cookie, opts.user_agent)

    try:
        UA = config['user-agent']
        COOKIE = config['cookie']
    except KeyError:
        print("Cookie or User-Agent not defined")
        parser.print_help()
        sys.exit(1)

    if opts.artist:
        artist = opts.artist.strip().replace(' ', '-')
        args = [f'https://{DOMAIN}/artist/{artist}/']

    if opts.input_file:
        with open(opts.input_file, 'r') as fp:
            urls = [i.strip() for i in fp.readlines() if DOMAIN in i]
    else:
        urls = [i for i in args if DOMAIN in i]

    try:
        asyncio.run(main(urls))
    except KeyboardInterrupt:
        pass
    finally:
        print('\nbye')
