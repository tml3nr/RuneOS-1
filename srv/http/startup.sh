#!/bin/bash

# 0. wait for usb mount 10 sec
# 1. mpdconf.sh
#   - probe sound devices
#   - populate mpd.conf
#   - start mpd, mpdidle
# 2. set mpd sound device
# 3. set sound profile
# 4. autoplay
# 5. check addons update
# 6. disable wlan power saving

i=0
while $( sleep 1 ); do
	grep -q '/mnt/MPD/USB' /proc/mounts && break
	
	(( i++ ))
	if (( i > 10 )); then
		curl -s -X POST 'http://localhost/pub?id=notify' -d '{ "title": "USB Drive", "text": "No USB drive found.", "icon": "usbdrive" }'
		break
	fi
done

if [[ -e /srv/http/runonce.sh ]]; then
	/srv/http/runonce.sh          # includes mpdconf.sh
else
	/srv/http/settings/mpdconf.sh # mpd mpdidle start here
fi

dirsystem=/srv/http/data/system

[[ -e $dirsystem/mpd-crossfade ]] && mpc -q $( cat $dirsystem/mpd-crossfade )

[[ -e $dirsystem/localbrowser ]] && systemctl start localbrowser

audiooutput=$( cat $dirsystem/audiooutput )
if [[ -z $audiooutput ]] || ! mpc outputs | grep -q "$audiooutput"; then
	echo "$( mpc outputs | head -1 | awk -F"[()]" '{print $2}' )" > $dirsystem/audiooutput
fi

/srv/http/settings/soundprofile.sh $( cat $dirsystem/soundprofile )

mountpoints=$( grep /mnt/MPD/NAS /etc/fstab | awk '{print $2}' )
if [[ -n "$mountpoints" ]]; then
	ip=$( grep '/mnt/MPD/NAS' /etc/fstab | tail -1 | cut -d' ' -f1 | sed 's|^//||; s|:*/.*$||' )
	sleep 10 # wait for network interfaces
	i=0
	while $( sleep 1 ); do
		ping -c 1 -w 1 $ip &> /dev/null && break
		
		(( i++ ))
		if (( i > 20 )); then
			echo 'NAS mount failed.<br><br><gr>Try reboot again.</gr>' > /srv/http/data/tmp/reboot
			curl -s -X POST 'http://localhost/pub?id=reload' -d 1
			exit
		fi
	done

	for mountpoint in $mountpoints; do
		mount $mountpoint
	done
fi

[[ -e $dirsystem/autoplay ]] && mpc -q play

if [[ -z "$mountpoints" ]]; then
	sleep 10
	i=0
	while $( sleep 1 ); do
		(( i++ ))
		 ip a show wlan0 &> /dev/null || (( i > 20 )) && break
	done
fi

wlans=$( ip a | grep 'wlan.:' | sed 's/.*: \(.*\):.*/\1/' )
if [[ -n "$wlans" ]]; then
	if [[ -e $dirsystem/accesspoint ]]; then
		ifconfig wlan0 $( grep router /etc/dnsmasq.conf | cut -d, -f2 )
		systemctl start dnsmasq hostapd
	fi
	
	sleep 15 # wait "power_save" ready for setting
	
	for wlan in $wlans; do
		iw $wlan set power_save off
	done
fi

/srv/http/addonsupdate.sh
