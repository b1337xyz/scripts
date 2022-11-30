#!/usr/bin/env python3
import i3ipc
from sys import argv

args = argv[1:]
con = i3ipc.Connection()
tree = con.get_tree()
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
bar = scr_height - focused.workspace().rect.height
resize = '-r' in args

if 'off' in focused.floating:
    focused.command('floating toggle')

if resize and ('up' in args or 'down' in args):
    x = scr_x
    win_width  = workspace.rect.width
    win_height = workspace.rect.height // 2
if resize and ('left' in args or 'right' in args):
    y = bar
    win_width  = workspace.rect.width // 2
    win_height = workspace.rect.height
if resize and 'center' in args:
    win_width  = (workspace.rect.width  * 70) // 100
    win_height = (workspace.rect.height * 65) // 100

if 'up' in args:
    y = bar
if 'down' in args:
    y = scr_height - win_height
if 'left' in args:
    x = scr_x
if 'right' in args:
    x = scr_width - win_width
if 'center' in args:
    x = scr_x + (workspace.rect.width  // 2) - (win_width  // 2)
    y = scr_y + (workspace.rect.height // 2) - (win_height // 2)

if resize:
    con.command('resize set {} {}'.format(win_width, win_height))
con.command('move position {} {}'.format(x, y))
