#!/usr/bin/env python3
import sys
import i3ipc
import subprocess

dmenu_args = ['-i', '-l', '10', '-c']
i3 = i3ipc.Connection()
tree = i3.get_tree()
scratch = tree.scratchpad()
focused = tree.find_focused()
cur_con_is_sp = False
sp_windows = {
    node.find_named('.*')[0].name: node.nodes[0]
    for node in scratch.floating_nodes
}
if len(sp_windows) == 0:  # happens also when the only scratchpad is focused
    sys.exit(0)
elif len(sp_windows) == 1:
    i3.command('scratchpad show')
    k = list(sp_windows.keys())[-1]
    sp_windows[k].command('focus')
    # sp_windows[k].command('floating toggle')
    sys.exit(0)

p = focused
while p.type != 'workspace':
    if p.floating and (p.scratchpad_state != 'none'):
        cur_con_is_sp = True
        break
    p = p.parent
if cur_con_is_sp:
    i3.command('scratchpad show')
    sys.exit(0)

dm_proc = subprocess.Popen(
   ["dmenu"] + dmenu_args,
   stdin=subprocess.PIPE,
   stdout=subprocess.PIPE,
   universal_newlines=True
)
sel_focus = dm_proc.communicate('\n'.join(sp_windows.keys()))
if dm_proc.returncode != 0:  # possibly user pressed Esc, do nothing
    sys.exit(1)
focus_win_name = sel_focus[0].strip()
try:
    sp_windows[focus_win_name].command('focus')
    # sp_windows[focus_win_name].command('floating toggle')
except KeyError:
    sys.exit(2)
