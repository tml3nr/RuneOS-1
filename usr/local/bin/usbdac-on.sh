#!/bin/bash

# for startup udev before /dev/sda1 mounted
[[ ! -e /srv/http/data/system ]] && exit

/usr/local/bin/usbdac.sh on & disown
