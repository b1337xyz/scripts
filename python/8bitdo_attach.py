#!/usr/bin/env python3

# use `lsusb` to get VENDOR_ID and MODEL_ID
VENDOR_ID = 0x2dc8
MODEL_ID = 0x3011

from time import sleep
import hid
import os

if os.getgid() != 0:
    print('You need root privileges to run this script')
    exit(1)

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
    exit(1)

try:
    print(gamepad.get_product_string())
    gamepad.set_nonblocking(True)
    while True:
        sleep(9000)
finally:
    os.remove(lock)
    gamepad.close()
