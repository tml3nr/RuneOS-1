#!/bin/bash

# function for verify names
cols=$( tput cols )
showData() {
    printf %"$cols"s | tr ' ' -
    echo $1
    echo $2
    printf %"$cols"s | tr ' ' -
}

# get ROOT partition and verify
ROOT=$( df | grep ROOT | awk '{print $NF}' )
showData "$( df -h | grep ROOT )" "ROOT: $ROOT"
echo -e "\nVerify ROOT partition\n"
printf 'Correct ROOT partition? (Y/n): '
read ans
[[ $ans != Y || $ans != y ]] && exit

# credential
echo -e "\nWi-Fi connection\n"
printf 'SSID: '
read ssid
printf 'Password: '
read password
printf 'wpa or wep: '
read wpa

# profile
echo "Interface=wlan0
Connection=wireless
IP=dhcp
ESSID=\"$ssid\"
Security=$wpa
Key=$password" > "$ROOT/etc/netctl/$ssid"

# enable startup
dir="$ROOT/etc/systemd/system/netctl@$ssid.service.d"
mkdir $dir
echo '[Unit]
BindsTo=sys-subsystem-net-devices-wlan0.device
After=sys-subsystem-net-devices-wlan0.device' > "$dir/profile.conf"

cd $ROOT/etc/systemd/system/multi-user.target.wants
ln -s ../../../../lib/systemd/system/netctl@.service "netctl@$ssid.service"
cd

# unmount
echo Unmount ROOT partition ...
umount -l $ROOT

echo -e ""\nMove micro SD card to RPi and power on\n
