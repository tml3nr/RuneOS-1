#!/bin/bash

. /srv/http/addons-functions.sh

name=$( tcolor 'RuneAudio+R e' )

title -l '=' "$bar $name Reset ..."

#--------------------------------------------------------
for addon in aria gpio tran; do
	uninstall_$addon.sh 2> /dev/null
done
#--------------------------------------------------------
echo -e "\n$bar Reset MPD status ..."

systemctl restart mpd  # for stop updating
mpc -q volume 50; mpc -q repeat 0; mpc -q random 0; mpc -q single 0; mpc -q consume 0
mpc clear
#--------------------------------------------------------
echo -e "\n$bar Reset mirrorlist ..."

rm /etc/pacman.d/mirrorlist*
wgetnc https://github.com/archlinuxarm/PKGBUILDs/raw/master/core/pacman-mirrorlist/mirrorlist -P /etc/pacman.d
#--------------------------------------------------------
echo -e "\n$bar Clear Chromium and pacman cache ..."

rm -rf /srv/http/.cache/chromium/Default/*
rm -f /var/cache/pacman/pkg/*
rm -f /root/{.bash_history,.wget-hsts}
#--------------------------------------------------------
echo -e "\n$bar Clear USB mounts ..."

mounts=( $( ls -d /mnt/MPD/USB/*/ 2> /dev/null ) )
if (( ${#mounts[@]} > 0 )); then
	for mount in "${mounts[@]}"; do
		udevil umount -l "$mount"
	done
fi
rm -rf /mnt/MPD/USB/*
#--------------------------------------------------------
mounts=( $( ls -d /mnt/MPD/NAS/*/ 2> /dev/null ) )
if (( ${#mounts[@]} > 0 )); then
	echo -e "\n$bar Clear NAS mounts ..."
	for mount in "${mounts[@]}"; do
		umount -l "$mount"
		rmdir "$mount"
		sed -i "|$mount| d" /etc/fstab
	done
	rm -rf /mnt/MPD/NAS/*
fi
#--------------------------------------------------------
echo -e "\n$bar Clear database and settings ..."

rm -r /srv/http/data
runesettings.sh
#--------------------------------------------------------
if journalctl -b | grep -q '(mmcblk0p1): Volume was not properly unmounted'; then
	echo -e "\n$bar Fix mmcblk0 dirty bit from unproperly unmount..."
	fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'
fi
#--------------------------------------------------------

title "$bar $name Reset successfully."
