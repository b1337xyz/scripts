#!/usr/bin/env python3
from time import sleep
import hid
import os

# > /etc/systemd/system/8bitdo.service
# [Service]
# ExecStart=-8bitdo_connect.py
# RestartKillSignal=9

# > /etc/udev/rules.d/90-8bitdo.rules
# SUBSYSTEM=="usb", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="3011", RUN+="/usr/bin/systemctl restart 8bitdo.service"

# > /etc/udev/rules.d/99-hidraw-permissions.rules
# KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", GROUP="input"

for dev in hid.enumerate():
    s = dev.get('manufacturer_string')
    if s == '8BitDo':
        vendor_id, product_id = dev['vendor_id'], dev['product_id']
        gamepad = hid.device()
        gamepad.open(vendor_id, product_id)
        break
else:
    exit(0)

try:
    gamepad.set_nonblocking(True)
    while True:
        sleep(900)
finally:
    gamepad.close()
