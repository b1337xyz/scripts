#!/usr/bin/env python3
import i3ipc
from sys import argv

args = argv[1:]
con = i3ipc.Connection()

# shrink/grow width/height <n> px
con.command('resize {}'.format(' '.join(args)))

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

if x < scr_x:
    x = scr_x
if x + win_width > scr_width:
    x = scr_width - win_width
if y < scr_y:
    y = scr_y
if y + win_height > scr_height:
    y = scr_height - win_height

con.command('move position {} {}'.format(x, y))
