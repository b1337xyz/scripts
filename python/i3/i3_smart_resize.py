#!/usr/bin/env python3
from i3ipc import Connection, Event
from time import sleep
from os import system


def smart_resize(i3, e):
    cmd = e.binding.command
    if cmd.startswith('resize '):
        tree = i3.get_tree()
        focused = tree.find_focused()
        workspace = focused.workspace()
        scr_x = workspace.rect.x
        scr_y = workspace.rect.y
        scr_width = scr_x + workspace.rect.width
        scr_height = scr_y + workspace.rect.height
        win_width = focused.rect.width
        win_height = focused.rect.height
        old_x = focused.rect.x
        old_y = focused.rect.y
        x = old_x
        y = old_y

        if x < scr_x:
            x = scr_x
        elif x + win_width > scr_width:
            x = scr_width - win_width
        if y < scr_y:
            y = scr_y
        elif y + win_height > scr_height:
            y = scr_height - win_height

        if x != old_x or y != old_y:
            i3.command('move position {} {}'.format(x, y))


if __name__ == '__main__':
    while system('pgrep -x i3 >/dev/null') == 0:
        try:
            i3 = Connection()
            i3.on(Event["BINDING"], smart_resize)
            i3.main()
        except KeyboardInterrupt:
            break
        except FileNotFoundError:
            continue
        sleep(1)
