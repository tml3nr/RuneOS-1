#!/bin/bash

version=e2

trap 'rm -f /var/lib/pacman/db.lck; clear; exit' INT

hwcode=$( cat /proc/cpuinfo | grep Revision | tail -c 4 | cut -c 1-2 )
echo 08 0c 0d 0e 11 | grep -q $hwcode && wireless=1 || wireless=

cols=$( tput cols )
hr() { printf "\e[36m%*s\e[m\n" $cols | tr ' ' -; }

hr
echo -e "\n\e[36mInitialize Arch Linux Arm ...\e[m\n"
hr

pacman-key --init
pacman-key --populate archlinuxarm

# fill entropy pool (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

# fix dns errors
systemctl stop systemd-resolved

# dialog package
pacman -Sy --noconfirm --needed dialog

#----------------------------------------------------------------------------
title="Create RuneAudio+R $version"
dialog  --backtitle "$title" --colors \
	--infobox "\n\n                \Z1RuneAudio+R $version\Z0" 7 50
sleep 3

    avahi='\Z1Avahi\Z0     - URL as: runeaudio.local'
    bluez='\Z1Bluez\Z0     - Bluetooth supports'
 chromium='\Z1Chromium\Z0  - Browser on RPi'
   ffmpeg='\Z1FFmpeg\Z0    - Extended decoder'
  hostapd='\Z1hostapd\Z0   - RPi access point'
      kid='\Z1Kid3\Z0      - Metadata tag editor'
   python='\Z1Python\Z0    - Programming language'
    samba='\Z1Samba\Z0     - File sharing'
shairport='\Z1Shairport\Z0 - AirPlay'
 upmpdcli='\Z1upmpdcli\Z0  - UPnP client'

selectFeatures() {
	select=$( dialog --backtitle "$title" --colors \
	   --output-fd 1 \
	   --checklist '\Z1Select features to install:\n
\Z4[space] = Select / Deselect\Z0' 0 0 10 \
			1 "$avahi" on \
			2 "$bluez" on \
			3 "$chromium" on \
			4 "$ffmpeg" on \
			5 "$hostapd" on \
			6 "$kid" on \
			7 "$python" on \
			8 "$samba" on \
			9 "$shairport" on \
			10 "$upmpdcli" on )
	
	select=" $select "
	[[ $select == *' 1 '* ]] && features+='avahi ' && list+="$avahi\n"
	[[ $select == *' 2 '* ]] && features+='bluez bluez-utils ' && list+="$bluez\n"
	[[ $select == *' 3 '* ]] && features+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit ' && list+="$chromium\n"
	[[ $select == *' 4 '* ]] && features+='ffmpeg ' && list+="$ffmpeg\n"
	[[ $select == *' 5 '* ]] && features+='dnsmasq hostapd ' && list+="$hostapd\n"
	[[ $select == *' 6 '* ]] && kid3=1 && list+="$kid\n"
	[[ $select == *' 7 '* ]] && features+='python python-pip ' && list+="$python\n"
	[[ $select == *' 8 '* ]] && features+='samba ' && list+="$samba\n"
	[[ $select == *' 9 '* ]] && features+='shairport-sync ' && list+="$shairport\n"
	[[ $select == *' 10 '* ]] && upnp=1 && list+="$upmpdcli\n"
}
selectFeatures

dialog --backtitle "$title" --colors \
	--yesno "\n\Z1Confirm features to install:\Z0\n\n
$list\n\n" 0 0
[[ $? == 1 ]] && selectFeatures

clear

#----------------------------------------------------------------------------
echo -e "\n\e[36mSystem-wide kernel and packages upgrade ...\e[m\n"

pacman -Su --noconfirm --needed

packages='alsa-utils cronie dosfstools gcc ifplugd imagemagick mpd mpc nfs-utils nss-mdns ntfs-3g parted php-fpm python python-pip sudo udevil wget '

echo -e "\n\e[36mInstall packages ...\e[m\n"

pacman -S --noconfirm --needed $packages $features

[[ $pyt == y || $pyt == Y ]] && yes | pip --no-cache-dir install RPi.GPIO

echo -e "\n\e[36mInstall custom packages and web interface ...\e[m\n"

wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /

chmod 755 /srv/http/* /srv/http/settings/* /usr/local/bin/*
chown -R http:http /srv/http

# RPi 0, 1 - switch packages for armv6h
if echo 00 01 02 03 09 0c | grep -q $hwcode; then
	rm /root/*.xz
	mv /root/armv6h/* /root
fi

if [[ $blue == n || $blue == N || ! $wireless ]]; then
	rm /root/bluealsa* /root/armv6h/bluealsa* /boot/overlays/bcmbt.dtbo
	sed -i '/disable-wifi\|disable-bt/ d' /boot/config.txt
fi
[[ $kid3 == n || $kid3 == N ]] && rm /root/kid3*
[[ $upnp == n || $upnp == N ]] && rm /etc/upmpdcli.conf /root/{libupnpp*,upmpdcli*}

pacman -U --noconfirm --needed /root/*.xz

#---------------------------------------------------------------------------------
echo -e "\n\e[36mConfigure ...\e[m\n"

# RPi 0 - fix kernel panic
[[ $hwcode == 09 || $hwcode == 0c ]] && sed -i -e '/force_turbo=1/ i\over_voltage=2' -e '/dtparam=audio=on/ a\hdmi_drive=2' /boot/config.txt

# RPi 4
if [[ $hwcode == 11 ]]; then
	sed -i '/force_turbo=1/ d' /boot/config.txt
	mv /usr/lib/firmware/updates/brcm/BCM{4345C0,}.hcd
fi

# remove config of excluded features
[[ ! -e /usr/bin/avahi-daemon ]] && rm -r /etc/avahi/services
[[ ! -e /usr/bin/bluetoothctl ]] && rm -r /etc/systemd/system/bluetooth.service.d /root/blue*
[[ ! -e /usr/bin/hostapd ]] && rm -r /etc/{hostapd,dnsmasq.conf}
[[ ! -e /usr/bin/smbd ]] && rm -r /etc/samba
[[ ! -e /usr/bin/shairport-sync ]] && rm /etc/systemd/system/shairport*

# alsa
chmod -R 666 /var/lib/alsa  # fix permission
sed -i '/^TEST/ s/^/#/' /usr/lib/udev/rules.d/90-alsa-restore.rules   # omit test rules

# boot partition - fix dirty bits if any
fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'

# bluetooth (skip if removed bluetooth)
[[ -e /usr/bin/bluetoothctl ]] && sed -i 's/#*\(AutoEnable=\).*/\1true/' /etc/bluetooth/main.conf

# chromium
if [[ -e /usr/bin/chromium ]]; then
	# boot splash
	sed -i 's/\(console=\).*/\1tty3 plymouth.enable=0 quiet loglevel=0 logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
	ln -s /srv/http/assets/img/{NORMAL,start}.png
	# login prompt - remove
	systemctl disable getty@tty1
else
	rm -f /etc/systemd/system/{bootsplash,localbrowser}* /etc/X11/xinit/xinitrc /srv/http/assets/img/{CW,CCW,NORMAL,UD}* /root/*matchbox* /usr/local/bin/ply-image
fi

# cron - for addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addons-update.sh &' ) | crontab -

# lvm - remove invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - create missing log file
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# netctl - allow write for http
chmod -R 777 /etc/netctl

# nginx - custom 50x.html
mv -f /etc/nginx/html/50x.html{.custom,}

# password - set default
echo root:rune | chpasswd

# ssh - permit root
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# user - set expire to none
users=$( cut -d: -f1 /etc/passwd )
for user in $users; do
	chage -E -1 $user
done

# upmpdcli - fix: missing symlink and init RSA key
if [[ -e /usr/bin/upmpdcli ]]; then
	ln -s /lib/libjsoncpp.so.{21,20}
	mpd --no-config &> /dev/null
	upmpdcli &> /dev/null &
fi

# wireless-regdom
echo 'WIRELESS_REGDOM="00"' > /etc/conf.d/wireless-regdom

# startup services
systemctl daemon-reload
startup='cronie devmon@mpd nginx php-fpm startup '
[[ -e /usr/bin/avahi-daemon ]] && startup+='avahi-daemon '
[[ -e /usr/bin/chromium ]] && startup+='bootsplash localbrowser '

systemctl enable $startup

#---------------------------------------------------------------------------------
# data - settings directories
dirdata=/srv/http/data
dirdisplay=$dirdata/display
dirsystem=$dirdata/system
mkdir -p "$dirdata"
for dir in addons bookmarks coverarts display gpio lyrics mpd playlists sampling system tmp webradios; do
	mkdir -p "$dirdata/$dir"
done
# addons
echo $( grep -A 2 rare /srv/http/addons-list.php | tail -1 | cut -d"'" -f4 ) > /srv/http/data/addons/rare
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
echo 'RaspberryPi Analog Out' > $dirsystem/audiooutput
echo bcm2835 ALSA_1 > $dirsystem/sysname
echo 1 | tee $dirsystem/{localbrowser,onboard-audio,onboard-wlan} > /dev/null
echo RuneAudio | tee $dirsystem/{hostname,soundprofile} > /dev/null
echo 0 0 0 > $dirsystem/mpddb
echo '$2a$12$rNJSBU0FOJM/jP98tA.J7uzFWAnpbXFYx5q1pmNhPnXnUu3L1Zz6W' > $dirsystem/password
echo $version > $dirsystem/version

# mpd - music directories
mkdir -p /mnt/MPD/{NAS,SD,USB}

# set permissions and ownership
chown -R http:http "$dirdata"
chown -R mpd:audio "$dirdata/mpd" /mnt/MPD

# remove cache and files
rm *.zip /root/*.xz /usr/local/bin/create-* /var/cache/pacman/pkg/* /etc/motd
rm -r /root/armv6h

dialog --colors \
	--msgbox "\n      
      \Z1RuneAudio+R $version\Z0 built successfully.\n\n
            Press \Z1Enter\Z0 to reboot
" 9 50

shutdown -r now
