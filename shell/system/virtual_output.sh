#!/bin/sh
src=alsa_output.pci-0000_00_0e.0.analog-stereo
src=alsa_output.pci-0000_00_0e.0.hdmi-stereo

#pactl load-module module-null-sink sink_name=Virtual1
#pactl load-module module-loopback source="$src" sink=Virtual1
#pactl load-module module-loopback source=Virtual1.monitor sink="$out"

pacmd load-module module-remap-sink sink_name=virt1 master="$src"
