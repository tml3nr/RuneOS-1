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
if journalctl -b | grep -q '(mmcblk0p1): Volume was not properly unmounted'; then
	echo -e "\n$bar Fix mmcblk0 dirty bit from unproperly unmount..."
	fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'
fi
#--------------------------------------------------------
echo -e "\n$bar Reset database and settings ..."

rm -r /srv/http/data

# default settings:
# data and subdirectories
dirdata=/srv/http/data
dirdisplay=$dirdata/display
dirsystem=$dirdata/system
mkdir "$dirdata"
for dir in addons bookmarks coverarts display gpio lyrics mpd playlists sampling system tmp webradios; do
	mkdir "$dirdata/$dir"
done
# addons
echo $addoversion > /srv/http/data/addons/rre1
echo $version > $dirsystem/version
# display
playback="bars buttons cover time volume"
library="album artist albumartist composer coverart genre nas sd usb webradio"
miscel="count label plclear playbackswitch"
for item in $playback $library $miscel; do
	echo 1 > $dirdisplay/$item
done
# system
echo runeaudio > /etc/hostname
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo bcm2835 ALSA_1 > $dirsystem/audiooutput
echo 1 | tee $dirsystem/{localbrowser,onboard-audio,onboard-wlan} > /dev/null
echo RuneAudio | tee $dirsystem/{hostname,soundprofile} > /dev/null
echo 0 0 0 > $dirsystem/mpddb
echo '$2a$12$rNJSBU0FOJM/jP98tA.J7uzFWAnpbXFYx5q1pmNhPnXnUu3L1Zz6W' > $dirsystem/password

# set permissions and ownership
chown -R http:http "$dirdata"
chown -R mpd:audio "$dirdata/mpd"
#--------------------------------------------------------

title "$bar $name Reset successfully."
echo
echo -e "Reboot or Shutdown"
echo -e '  \e[36m0\e[m Reboot'
echo -e '  \e[36m1\e[m Shutdown'
echo
echo -e '\e[36m0\e[m / 1 ? '
read -n 1 answer
[[ $answer == 1 ]] && shutdown -r now || shutdown -h now
