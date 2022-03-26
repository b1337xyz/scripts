#!/usr/bin/env python3
import i3ipc
from optparse import OptionParser
usage = 'Usage: %prog [options]'
parser = OptionParser(usage=usage)
parser.add_option(
    '-r', '--resize', action='store_true',
    dest='resize', default=False
)
opts, args = parser.parse_args()

con = i3ipc.Connection()
tree = con.get_tree()
focused = tree.find_focused()
workspace = focused.workspace()
border = 4
scr_width = workspace.rect.width
scr_height = workspace.rect.height
scr_height = 768 if scr_height < 768 else scr_height
scr_x = workspace.rect.x
scr_y = workspace.rect.y
bar_height = 28
arg = args[0]


def main(arg):
    if 'off' in focused.floating:
        focused.command('floating toggle')

    # win_width = focused.rect.width
    # win_height = focused.rect.height

    if arg == 'top':
        width = scr_width
        height = scr_height // 2 - bar_height
        x = scr_x
        y = bar_height
    elif arg == 'top-left':
        width = scr_width // 2
        height = scr_height // 2 - bar_height
        x = scr_x
        y = bar_height
    elif arg == 'top-right':
        width = scr_width // 2
        height = scr_height // 2 - bar_height
        x = scr_x + scr_width // 2
        y = bar_height
    elif arg == 'left':
        width = scr_width // 2
        height = scr_height - bar_height
        x = scr_x
        y = bar_height
    elif arg == 'right':
        width = scr_width // 2
        height = scr_height - bar_height
        x = scr_x + scr_width // 2
        y = bar_height
    elif arg == 'bottom':
        width = scr_width
        height = scr_height // 2
        x = scr_x
        y = scr_height // 2
    elif arg == 'bottom-left':
        width = scr_width // 2
        height = scr_height // 2
        x = scr_x
        y = scr_height // 2
    elif arg == 'bottom-right':
        width = scr_width // 2
        height = scr_height // 2
        x = scr_x + scr_width // 2
        y = scr_height // 2
    elif arg == 'middle':
        con.command('move position center')
        width = (scr_width // 2) + 100
        height = (scr_height // 2) + 50
        x = (scr_x + scr_width // 2) - (width // 2)
        y = (scr_height // 2) - (height // 2) + bar_height
    y -= border
    x -= 2

    def run_cmd(cmd):
        con.command(cmd)

    if opts.resize:
        run_cmd('resize set {} {}'.format(width, height))
    run_cmd('move position {} {}'.format(x, y))


if __name__ == '__main__' and arg != 'debug':
    main(arg)
