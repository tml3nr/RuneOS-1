#!/bin/bash

bluetoothctl system-alias "$( cat /srv/http/data/system/hostname )"
bluetoothctl discoverable yes
bluetoothctl pairable yes
