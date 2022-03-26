#!/usr/bin/env python3
import i3ipc
import sys
import subprocess as sp

terminal = 'alacritty'
con = i3ipc.Connection()
tree = con.get_tree()
focused = tree.find_focused()
width = focused.rect.width
height = focused.rect.height
x = focused.rect.x
y = focused.rect.y
if 'off' in focused.floating:
    print('nothign to do')
    sys.exit(1)
if terminal not in focused.window_class.lower():
    print('nothign to do')
    sys.exit(1)

sp.call('alacritty --class floating_terminal &', shell=True)
fid = focused.id
while focused.id == fid:
    tree = con.get_tree()
    focused = tree.find_focused()

if terminal in focused.window_class.lower():
    con.command('resize set {} {}'.format(width, height))
    con.command('move position {} {}'.format(x, y))
