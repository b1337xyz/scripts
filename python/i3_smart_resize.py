#!/usr/bin/env python3
from i3ipc import Connection, Event

def smart_resize(i3, e):
    if e.binding.command.startswith('resize '):
        tree = i3.get_tree()
        focused = tree.find_focused()
        workspace = focused.workspace()
        scr_x = workspace.rect.x
        scr_y = workspace.rect.y
        scr_width  = scr_x + workspace.rect.width
        scr_height = scr_y + workspace.rect.height
        win_width  = focused.rect.width
        win_height = focused.rect.height
        x = focused.rect.x
        y = focused.rect.y

        if x < scr_x:
            x = scr_x
        if x + win_width > scr_width:
            x = scr_width - win_width
        if y < scr_y:
            y = scr_y
        if y + win_height > scr_height:
            y = scr_height - win_height

        i3.command('move position {} {}'.format(x, y))

if __name__ == '__main__':
    i3 = Connection()
    i3.on(Event["BINDING"], smart_resize)
    i3.main()
