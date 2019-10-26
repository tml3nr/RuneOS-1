#!/bin/bash

### hostname
	if [[ -e $dirsystem/hostname ]]; then
		name=$( cat $dirsystem/hostname )
		namelc=$( echo $name | tr '[:upper:]' '[:lower:]' )
		hostname $namelc
		echo $namelc > /etc/hostname
		sed -i "s/^\(ssid=\).*/\1$name/" /etc/hostapd/hostapd.conf &> /dev/null
		sed -i 's/\(zeroconf_name           "\).*/\1$name"/' /etc/mpd.conf
		sed -i "s/\(netbios name = \).*/\1$name/" /etc/samba/smb.conf &> /dev/null
		sed -i "s/^\(name = \).*/\1$name" /etc/shairport-sync.conf &> /dev/null
		sed -i "s/^\(friendlyname = \).*/\1$name/" /etc/upmpdcli.conf &> /dev/null
		sed -i "s/\(.*\[\).*\(\] \[.*\)/\1$namelc\2/" /etc/avahi/services/runeaudio.service
		sed -i "s/\(.*localdomain \).*/\1$namelc.local $namelc/" /etc/hosts
	fi
### accesspoint
	if [[ -e $dirsystem/accesspoint && -e /etc/hostapd/hostapd.conf ]]; then
		if [[ -e $dirsystem/accesspoint-passphrase ]]; then
			passphrase=$( cat $dirsystem/accesspoint-passphrase )
			ip=$( cat $dirsystem/accesspoint-ip )
			iprange=$( cat $dirsystem/accesspoint-iprange )
			sed -i -e "/wpa\|rsn_pairwise/ s/^#\+//
				 " -e "s/\(wpa_passphrase=\).*/\1$passphrase/
				 " /etc/hostapd/hostapd.conf
			sed -i -e "s/^\(dhcp-range=\).*/\1$iprange/
				 " -e "s/^\(dhcp-option-force=option:router,\).*/\1$ip/
				 " -e "s/^\(dhcp-option-force=option:dns-server,\).*/\1$ip/
				 " /etc/dnsmasq.conf
		fi
	fi
### airplay
	[[ -e $dirsystem/airplay && -e /etc/shairport-sync.conf ]] && systemctl enable --now shairport-sync
### color
	if [[ -e $dirdisplay/color ]]; then
		. /srv/http/addons-functions.sh
		setColor
	fi
### fstab
	if ls $dirsystem/fstab-* &> /dev/null; then
		files=( /srv/http/data/system/fstab-* )
		for file in "${files[@]}"; do
			cat $file >> /etc/fstab
		done
	fi
### localbrowser
	if [[ -e $dirsystem/localbrowser && -e /usr/bin/chromium ]]; then
		if [[ -e $dirsystem/localbrowser-cursor ]]; then
			sed -i -e "s/\(-use_cursor \).*/\1$( cat $dirsystem/localbrowser-cursor ) \&/
				 " -e "s/\(xset dpms 0 0 \).*/\1$( cat $dirsystem/localbrowser-screenoff ) \&/" /etc/X11/xinit/xinitrc
			cp $dirsystem/localbrowser-rotatecontent /etc/X11/xorg.conf.d/99-raspi-rotate.conf
			if [[ $( cat $dirsystem/localbrowser-overscan ) == 1 ]]; then
				sed -i '/^disable_overscan=1/ s/^#//' /boot/config.txt
			else
				sed -i '/^disable_overscan=1/ s/^/#/' /boot/config.txt
			fi
		fi
	fi
### login
	[[ -e $dirsystem/login ]] && sed -i 's/\(bind_to_address\).*/\1         "localhost"/' /etc/mpd.conf
### mpd.conf
	[[ -e $dirsystem/mpd-autoupdate ]] && sed -i 's/\(auto_update\s*"\).*/\1yes"/' /etc/mpd.conf
	[[ -e $dirsystem/mpd-buffer ]] && sed -i "s/\(audio_buffer_size\s*\"\).*/\1$( cat $dirsystem/mpd-buffer )\"/" /etc/mpd.conf
	[[ -e $dirsystem/mpd-ffmpeg ]] && sed -i '/ffmpeg/ {n;s/\(enabled\s*"\).*/\1yes"/}' /etc/mpd.conf
	[[ -e $dirsystem/mpd-mixertype ]] && sed -i "s/\(mixer_type\s*\"\).*/\1$( cat $dirsystem/mpd-mixertype )\"/" /etc/mpd.conf
	[[ -e $dirsystem/mpd-normalization ]] && sed -i 's/\(volume_normalization\s*"\).*/\1yes"/' /etc/mpd.conf
	[[ -e $dirsystem/mpd-replaygain ]] && sed -i "s/\(replaygain\s*\"\).*/\1$( cat $dirsystem/mpd-replaygain )\"/" /etc/mpd.conf
### netctl profiles
	if ls $dirsystem/netctl-* &> /dev/null; then
		files=( /srv/http/data/system/netctl-* )
		for file in "${files[@]}"; do
			cp "$file" /etc/netctl
		done
	fi
### ntp
	[[ -e $dirsystem/ntp ]] && sed -i "s/#*NTP=.*/NTP=$( cat $dirsystem/ntp )/" /etc/systemd/timesyncd.conf
### onboard devices
	[[ ! -e $dirsystem/onboard-audio ]] && sed -i 's/\(dtparam=audio=\).*/\1off/' /boot/config.txt
	[[ ! -e $dirsystem/onboard-bluetooth ]] && sed -i '/^#dtoverlay=pi3-disable-bt/ s/^#//' /boot/config.txt
	if [[ ! -e $dirsystem/onboard-wlan ]]; then
		sed -i '/^#dtoverlay=pi3-disable-wifi/ s/^#//' /boot/config.txt
		systemctl disable netctl-auto@wlan0
	fi
### samba
	if [[ -e $dirsystem/samba && -e /etc/samba ]]; then
		[[ -e $dirsystem/samba-writesd ]] && sed -i '/path = .*USB/ a\tread only = no' /etc/samba/smb.conf
		[[ -e $dirsystem/samba-writeusb ]] && sed -i '/path = .*LocalStorage/ a\tread only = no' /etc/samba/smb.conf
		
		systemctl enable --now nmb smb
	fi
### timezone
	[[ -e $dirsystem/timezone ]] && ln -sf /usr/share/zoneinfo/$( cat $dirsystem/timezone ) /etc/localtime
### upnp
	if [[ -e $dirsystem/upnp && /etc/upmpdcli.conf ]]; then
		setUpnp() {
			user=( $( cat $dirsystem/upnp-$1user ) )
			pass=( $( cat $dirsystem/upnp-$1pass ) )
			quality=( $( cat $dirsystem/upnp-$1quality 2> /dev/null ) )
			[[ $1 == qobuz ]] && qlty=formatid || qlty=quallity
			sed -i -e "s/#*\($1user = \).*/\1$user/
			 	" -e "s/#*\($1pass = \).*/\1$pass/
			 	" -e "s/#*\($1$qlty = \).*/\1$quality/
				 " /etc/upmpdcli.conf
		}
		[[ -e $dirsystem/upnp-gmusicuser ]] && setUpnp gmusic
		[[ -e $dirsystem/upnp-qobuzuser ]] && setUpnp qobuz
		[[ -e $dirsystem/upnp-tidaluser ]] && setUpnp tidal
		[[ -e $dirsystem/upnp-spotifyluser ]] && setUpnp spotify
		if [[ -e $dirsystem/upnp-ownqueue ]]; then
			sed -i '/^ownqueue/ d' /etc/upmpdcli.conf
		else
			sed -i '/^#ownqueue = / a\ownqueue = 0' /etc/upmpdcli.conf
		fi
		
		systemctl enable --now upmpdcli
	fi
fi
