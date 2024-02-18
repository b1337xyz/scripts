#!/usr/bin/env python3

# use `lsusb` to get VENDOR_ID and MODEL_ID
VENDOR_ID = 0x2dc8
MODEL_ID = 0x3011

from time import sleep
import hid
import os

lock = '/tmp/8bitdo.lock'
if os.path.exists(lock):
    print(f'lock file found ({lock}), already running?')
    exit(1)

os.umask(0o000)
open(lock, 'w').close()

gamepad = hid.device()
for _ in range(10):
    try:
        gamepad.open(VENDOR_ID, MODEL_ID)
        break
    except Exception:
        sleep(0.2)
else:
    print('''Try running as root or make the file:
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
