#!/bin/bash

rm $0

echo -e "\nVerify ROOT path"

ROOT=$( df | grep ROOT | awk '{print $NF}' )
if [[ -z $ROOT ]]; then
    echo -e "\nROOT path not found.\n"
	exit
fi

cols=$( tput cols )
printf %"$cols"s | tr ' ' -
echo $( df -h | grep ROOT )
echo ROOT: $ROOT
printf %"$cols"s | tr ' ' -
echo
read -rsn1 -p "Confirm ROOT path? (y/N): " ans; echo
[[ $ans != Y && $ans != y ]] && exit

echo -e "\nSetup Wi-Fi connection\n"

selectSecurity() {
	echo Security:
	tcolor 1 'WPA'
	tcolor 2 'WEP'
	tcolor 3 'None'
	read -p 'Select [1-3]: ' wpa
	[[ -z $wpa ]] || (( $wpa > 3 )) && echo -e "\nSelect 1, 2 or 3\n" && selectSecurity
}
setCredential() {
	echo
	read -p 'SSID: ' ssid
	read -p 'Password: ' password
	selectSecurity
	echo -e "\nSSID: $ssid\nPassword: $password\nSecurity: $wpa"
	read -rn1 -p "Confirm and continue? [y/N]: " ans; echo
	[[ $ans != Y && $ans != y ]] && setCredential
}
setCredential

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
umount -l $ROOT && echo -e "\n$ROOT unmounted.\nMove to Raspberry Pi."
