#!/bin/bash

rm $0

echo -e "\nVerify partition ROOT"

ROOT=$( df | grep ROOT | awk '{print $NF}' )
if [[ -z $ROOT ]]; then
    echo -e "\nPartition ROOT not found.\n"
	exit
fi

cols=$( tput cols )
printf %"$cols"s | tr ' ' -
echo $( df -h | grep ROOT )
echo ROOT: $ROOT
printf %"$cols"s | tr ' ' -
echo
read -rsn1 -p "Confirm partition ROOT? (y/N): " ans; echo
[[ $ans != Y && $ans != y ]] && exit

echo -e "\nSetup Wi-Fi connection\n"
printf 'SSID: '
read ssid
printf 'Password: '
read password
printf 'wpa or wep: '
read wpa
echo
read -rsn1 -p "Confirm and continue? (y/N): " ans; echo
[[ $ans != Y && $ans != y ]] && exit

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
umount -l $ROOT
if umount -l $ROOT; then
    echo -e "\nROOT partition unmounted."
    echo -e "Move to RPi and power on.\n"
fi
