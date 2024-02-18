#!/usr/bin/env python3
from time import sleep
import hid
import os

lock = '/tmp/8bitdo.lock'
if os.path.exists(lock):
    print(f'lock file found ({lock}), already running?')
    exit(1)
open(lock, 'w').close()

for dev in hid.enumerate():
    if dev.get('manufacturer_string') == '8BitDo':
        vendor_id, product_id = dev['vendor_id'], dev['product_id']
        break
else:
    print('8BitDo not found')
    exit(1)

gamepad = hid.device()
for _ in range(10):
    try:
        gamepad.open(vendor_id, product_id)
        break
    except Exception:
        sleep(0.2)
else:
    print('''Try running as root or make a udev rule:
> /etc/udev/rules.d/99-hidraw-permissions.rules
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="input"

Make sure you are in the `input` group''')
    exit(1)

try:
    print(gamepad.get_product_string())
    gamepad.set_nonblocking(True)
    while True:
        sleep(9000)
finally:
    os.remove(lock)
    gamepad.close()
