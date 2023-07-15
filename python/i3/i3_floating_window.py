#!/usr/bin/env python3
from i3ipc import Connection, Event

def main(i3, e):
    if e.change != 'new':
        return

    tree = i3.get_tree()
    focused = tree.find_focused()
    if not focused.floating:
        return

    workspace = focused.workspace()
    nodes = workspace.floating_nodes
    x = workspace.rect.x
    y = workspace.rect.y
    for node in nodes:
        x += 20
        y += 20
    i3.command('move position {} {}'.format(x, y))


if __name__ == '__main__':
    i3 = Connection()
    i3.on(Event["WINDOW"], main)
    i3.main()
