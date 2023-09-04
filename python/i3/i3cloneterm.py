#!/usr/bin/env python3
import i3ipc
import sys

terminal = 'alacritty'

i3 = i3ipc.Connection()
tree = i3.get_tree()
focused = tree.find_focused()
width = focused.rect.width
height = focused.rect.height
x = focused.rect.x
y = focused.rect.y
if 'off' in focused.floating:
    sys.exit(1)

# sp.call('alacritty --class floating_window &', shell=True)
i3.command('exec alacritty --class floating_window')
fid = focused.id
while focused.id == fid:
    tree = i3.get_tree()
    focused = tree.find_focused()

i3.command('resize set {} {}'.format(width, height))
i3.command('move position {} {}'.format(x, y))
