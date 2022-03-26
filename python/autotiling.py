#!/usr/bin/env python3
# simplified version of https://github.com/nwg-piotr/autotiling
from i3ipc import Connection, Event


def switch_splitting(i3, e):
    con = i3.get_tree().find_focused()
    is_floating = "_on" in con.floating
    is_full_screen = con.fullscreen_mode == 1
    is_stacked = con.parent.layout == "stacked"
    is_tabbed = con.parent.layout == "tabbed"
    if (
        not is_floating
        and not is_stacked
        and not is_tabbed
        and not is_full_screen
    ):
        new_layout = "splitv" if con.rect.height > con.rect.width else "splith"
        if new_layout != con.parent.layout:
            i3.command(new_layout)


events = ["WINDOW", "MODE"]
i3 = Connection()
for e in events:
    i3.on(Event[e], switch_splitting)
i3.main()
