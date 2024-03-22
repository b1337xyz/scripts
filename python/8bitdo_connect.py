#!/usr/bin/env python3
from time import sleep
import hid
import os

for dev in hid.enumerate():
    s = dev.get('manufacturer_string')
    print(dev)
    if s == '8BitDo':
        vendor_id, product_id = dev['vendor_id'], dev['product_id']
        gamepad = hid.device()
        gamepad.open(vendor_id, product_id)
        print(s, 'connected')
        break
else:
    exit(0)

try:
    gamepad.set_nonblocking(True)
    while True:
        sleep(900)
finally:
    gamepad.close()
