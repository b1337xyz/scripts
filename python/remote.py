#!/usr/bin/env python3
from stat import S_ISSOCK
import urwid
import os
import socket
import subprocess as sp
import json

# Resources:
# https://stackoverflow.com/questions/52252730/how-do-you-make-buttons-of-the-python-library-urwid-look-pretty

os.environ.update({
    "DISPLAY": ":0",
    "PATH": os.environ["PATH"] + ':/home/anon/.local/bin',
    'I3SOCK': '/run/user/1000/i3/ipc.sock',
})

is_socket = lambda file_path: S_ISSOCK(os.stat(file_path).st_mode)
for i in os.listdir('/tmp'):
    file_path = f'/tmp/{i}'
    if i.startswith('mpv') and is_socket(file_path):
        SOCKET_PATH = file_path
        break
else:
    SOCKET_PATH = '/tmp/mpvsocket'

commands = {
    'mpv': {
        "Pause/Unpause": ["cycle", "pause"],
        "Mute/Unmute": ["cycle", "mute"],
        "Next": ["playlist-next"],
        "Previous": ["playlist-prev"],
        "Next Chapter": ["add", "chapter", "1"],
        "Previous Chapter": ["add", "chapter", "-1"],
        "Forward": ["seek", "50"],
        "Backward": ["seek", "-50"],
        "Volume Up": ["add", "volume", "10"],
        "Volume Down": ["add", "volume", "-10"],
        "Show controls": ["script-binding", "stats/display-stats"],
        "Screenshot": ["screenshot"]
    },
    'cmd': {
        'Turn off monitor': ['i3-msg', 'exec', 'brightnessctl s 0'],
        'Turn on monitor': ['i3-msg', 'exec', 'brightnessctl s 5%'],
        # 'Turn off monitor': ['brightnessctl', 's', '0'],
        # 'Turn on monitor': ['brightnessctl', 's', '5%'],
        "Volume Up": ["volupdown.sh", "up"],
        "Volume Down": ["volupdown.sh", "down"],
    },
    'cmus': {
        "CMUS Next": ['cmus-remote', '-n'],
        "CMUS Previous": ['cmus-remote', '-r'],
        "CMUS Play/Pause": ['cmus-remote', '-u'],
    },
    'playerctl': {
        "Next": ['playerctl', 'next'],
        "Previous": ['playerctl', 'prev'],
        "Play/Pause": ['playerctl', 'play-pause'],
    }
}


def mpv_on_click(btn):
    cmd = {'command': commands["mpv"][btn.label]}
    try:
        mpv = socket.socket(socket.AF_UNIX)
        mpv.connect(SOCKET_PATH)
        mpv.send(json.dumps(cmd).encode('utf-8') + b'\n')
        mpv.close()
        footer.set_text(f'Success')
    except Exception as err:
        footer.set_text(f'Error: {err}')


def cmd_on_click(*args):
    btn, k = args
    cmd = commands[k].get(btn.label)
    try:
        p = sp.run(cmd, stdout=sp.PIPE, stderr=sp.PIPE,
                   env=os.environ.copy())
        if p.stderr:
            footer.set_text(f'Error, {p.stderr.decode()}')
        else:
            footer.set_text(f'Success {p.stdout.decode()}')
    except Exception as err:
        footer.set_text(f'Error: {err}')


def on_exit(btn):
    raise urwid.ExitMainLoop()


class CustomButton(urwid.Button):
    button_left = urwid.Text('')
    button_right = urwid.Text('')


class BoxButton(urwid.WidgetWrap):
    _border_char = u'─'

    def __init__(self, label, align='left', on_press=None, user_data=None):
        self.widget = urwid.Text([u'\n {} \n'.format(label)], align=align)
        self.widget = urwid.AttrMap(self.widget, '', 'highlight')
        self._hidden_btn = urwid.Button(label, on_press, user_data)
        super(BoxButton, self).__init__(self.widget)

    def selectable(self):
        return True

    def keypress(self, *args, **kw):
        return self._hidden_btn.keypress(*args, **kw)

    def mouse_event(self, *args, **kw):
        return self._hidden_btn.mouse_event(*args, **kw)


def add_buttons(title, items, on_press, user_data=None):
    title = urwid.Text(("title", f'< {title} >'), align='center')
    title = urwid.AttrMap(title, 'title_bar')
    body = [title]
    buttons = []
    for i, item in enumerate(items):
        btn = BoxButton(item, on_press=on_press, user_data=user_data)
        buttons.append(btn)
        if len(buttons) == 2:
            body.append(urwid.Columns(buttons, dividechars=0))
            buttons = []
        elif i == len(items) - 1:
            body.append(btn)
    return body


def main():
    global footer, loop
    body = []
    body.extend(add_buttons("MPV Controls", commands['mpv'], mpv_on_click))
    body.extend(add_buttons("Commands", commands['cmd'], cmd_on_click, 'cmd'))
    body.extend(add_buttons("CMUS", commands['cmus'], cmd_on_click, 'cmus'))
    body.extend(add_buttons("Player", commands['playerctl'], cmd_on_click, 'playerctl'))
    footer = urwid.Text("")
    widget = urwid.Pile(body + [
        BoxButton("Exit", align='center', on_press=on_exit),
        footer
    ])
    widget = urwid.Filler(widget, 'top')
    palette = [
        (None, 'default,bold', 'default'),
        ("title", "black,bold", "white"),
        ("title_bar", "default,bold", "white"),
        ("status", "dark red,bold", "default"),
        ('highlight', 'black', 'dark blue'),
    ]
    loop = urwid.MainLoop(widget, palette)
    # loop.set_alarm_in(10, refresh)
    loop.run()


if __name__ == '__main__':
    main()
