#!/usr/bin/env python3
from time import sleep
import subprocess as sp
import requests
import json
import os

HOME = os.getenv('HOME')
CONFIG = os.path.join(HOME, '.cache/twitch.json')

# See https://dev.twitch.tv/docs/authentication/getting-tokens-oauth
CLIENT_ID = ''
SECRET = ''
USER_ID = ''


class Twitch:
    def __init__(self):
        with open(CONFIG, 'r') as fp:
            config = json.load(fp)
        self.token = config['access_token']
        self.refresh_token = config['refresh_token']


    def refresh(self):
        url = 'https://id.twitch.tv/oauth2/token'
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        r = requests.post(url, params={
            'grant_type': 'refresh_token',
            'client_id': CLIENT_ID,
            'client_secret': SECRET,
            'refresh_token': self.refresh_token
        }, headers=headers)
        assert r.ok
        j = r.json()
        self.token = j['access_token']
        self.refresh_token = j['refresh_token']
        with open(CONFIG, 'w') as fp:
            json.dump(j, fp)


    def get_streams(self):
        headers = {
            'Client-ID': CLIENT_ID,
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        url = f"https://api.twitch.tv/helix/streams/followed?user_id={USER_ID}"
        r = requests.get(url, headers=headers)
        if not r.ok:
            self.refresh()
            return self.get_streams()
        else:
            return r.json()['data']


    def run(self):
        users = list()
        while True:
            streams = list()
            for i in self.get_streams():
                streams.append(i['user_id'])
                thumb_url = i['thumbnail_url'].replace('.jpg', '.png')
                thumb_url = thumb_url.replace('{width}',  '360')
                thumb_url = thumb_url.replace('{height}', '192')
                r = requests.get(thumb_url, stream=True)
                icon = '/tmp/twitch.png'
                img = r.raw.read()
                with open(icon, 'wb') as fp:
                    fp.write(img)

                if i['user_id'] not in users:
                    title = i['title']
                    title = title[:97] + '...' if len(title) > 100 else title
                    sp.run([
                        'notify-send', '-i', icon,
                        i['user_name'], f'{i["game_name"]}\n{title}'
                    ])
                    users.append(i['user_id'])
            users = [i for i in users if i in streams]
            sleep(15 * 60)


if __name__ == '__main__':
    Twitch().run()
