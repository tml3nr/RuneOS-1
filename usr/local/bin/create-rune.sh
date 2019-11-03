#!/bin/bash

version=e2
addoversion=20191101

cols=$( tput cols )
hr() {
	printf %"$cols"s | tr ' ' -; echo
}

hr
echo -e "\n\e[36mCreate RuneAudio+Re ...\e[m\n"
hr

#-------------------------------------------------------------------
echo -e "\n\e[m36Features ...\e[m\n"

selectFeatures() {
	read -ren 1 -p $'Install \e[36mall packages\e[m [y/n]: ' ans; echo
	if [[ $ans == y || $ans == Y ]]; then
		packages+='avahi dnsmasq ffmpeg hostapd python python-pip samba shairport-sync '
		# RPi 0W, 3, 4
		[[ $wireless ]] && packages+='bluez bluez-utils '
		# RPi 2, 3, 4
		echo 04 08 0d 0e 11 | grep -q $hwcode && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit '

		echo -e "Install \e[36mall packages\e[m\n"
		read -ren 1 -p $'Confirm and continue? [y/n]: ' ans; echo
		[[ $ans != y && $ans != Y ]] && selectFeature
	else
		list=

		pkg="\e[36mAvahi\e[m - Connect by: runeaudio.local"
		read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
		[[ $ans == y || $ans == Y ]] && packages+='avahi ' && list+="$pkg\n"

		if [[ $wireless ]]; then
			pkg="\e[36mBluez\e[m - Bluetooth supports"
			read -ren 1 -p $"Install $pkg [y/n]: " blue; echo
			[[ $blue == y || $blue == Y ]] && packages+='bluez bluez-utils ' && list+="$pkg\n"
		fi

		if echo 04 08 0d 0e 11 | grep -q $hwcode; then
			pkg="\e[36mChromium\e[m - Browser on RPi"
			read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
			[[ $ans == y || $ans == Y ]] && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit ' && list+="$pkg\n"
		fi

		pkg="\e[36mFFmpeg\e[m - Extended decoder"
		read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
		[[ $ans == y || $ans == Y ]] && packages+='ffmpeg ' && list+="$pkg\n"

		pkg="\e[36mhostapd\e[m - RPi access point"
		read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
		[[ $ans == y || $ans == Y ]] && packages+='dnsmasq hostapd ' && list+="$pkg\n"

		pkg="\e[36mKid3\e[m - Metadata tag editor"
		read -ren 1 -p $"Install $pkg [y/n]: " kid3; echo
		[[ $kid3 == y || $kid3 == Y ]] && list+="$pkg\n"

		pkg="\e[36mPython\e[m - Programming language"
		read -ren 1 -p $"Install $pkg [y/n]: " pyth; echo
		[[ $pyth == y || $pyth == Y ]] && packages+='python python-pip ' && list+="$pkg\n"

		pkg="\e[36mSamba\e[m - File sharing"
		read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
		[[ $ans == y || $ans == Y ]] && packages+='samba ' && list+="$pkg\n"

		pkg="\e[36mShairport-sync\e[m - AirPlay"
		read -ren 1 -p $"Install $pkg [y/n]: " ans; echo
		[[ $ans == y || $ans == Y ]] && packages+='shairport-sync ' && list+="$pkg\n"

		pkg="\e[36mupmpdcli\e[m - UPnP"
		read -ren 1 -p $"Install $pkg [y/n]: " upnp; echo
		[[ $upnp == y || $upnp == Y ]] && list+="$pkg\n"

		if [[ -n $list ]]; then
			list="Install packages:\n$list\n"
			read -ren 1 -p $'Confirm and continue? [y/n]: ' ans; echo
			[[ $ans != y && $ans != Y ]] && selectFeature
		fi
	fi
}
selectFeatures
#-------------------------------------------------------------------
echo -e "\n\n\e[36mInitialize PGP key ...\e[m\n"

pacman-key --init
pacman-key --populate archlinuxarm

# fill entropy pool (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

# fix dns errors
systemctl stop systemd-resolved

echo -e "\n\e[36mSystem-wide kernel and packages upgrade ...\e[m\n"

pacman -Syu --noconfirm --needed

packages='alsa-utils cronie dosfstools gcc ifplugd imagemagick mpd mpc nfs-utils nss-mdns ntfs-3g parted php-fpm python python-pip sudo udevil wget '

# get RPi hardware code
hwcode=$( cat /proc/cpuinfo | grep Revision | tail -c 4 | cut -c 1-2 )
echo 08 0c 0d 0e 11 | grep -q $hwcode && wireless=1 || wireless=

#-----------------------------------------------------------------------------
echo -e "\n\e[36mInstall packages ...\e[m\n"

pacman -S --noconfirm --needed $packages
[[ $pyt == y || $pyt == Y ]] && yes | pip --no-cache-dir install RPi.GPIO

echo -e "\n\e[36mInstall custom packages and web interface ...\e[m\n"

wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /

# no onboard wireless
[[ ! $wireless ]] && rm /root/bluealsa* /root/armv6h/bluealsa* /boot/overlays/bcmbt.dtbo

# RPi 0, 1
if echo 00 01 02 03 09 0c | grep -q $hwcode; then
    rm /root/*.xz
    mv /root/armv6h/* /root
fi

chmod 755 /srv/http/* /srv/http/settings/* /usr/local/bin/*
chown -R http:http /srv/http

# remove config of excluded packages
[[ ! -e /usr/bin/avahi-daemon ]] && rm -r /etc/avahi/services
if [[ ! -e /usr/bin/chromium ]]; then
    rm -f libmatchbox* matchbox*
    rm /etc/systemd/system/localbrowser*
    rm /etc/X11/xinit/xinitrc
fi
[[ ! -e /usr/bin/bluetoothctl ]] && rm -r /etc/systemd/system/bluetooth.service.d /root/blue*
[[ ! -e /usr/bin/hostapd ]] && rm -r /etc/{hostapd,dnsmasq.conf}
[[ $kid3 == n || $kid3 == N ]] && rm /root/kid3*
[[ ! -e /usr/bin/smbd ]] && rm -r /etc/samba
[[ ! -e /usr/bin/shairport-sync ]] && rm /etc/systemd/system/shairport*
[[ $upnp == n || $upnp == N ]] && rm /etc/upmpdcli.conf /root/{libupnpp*,upmpdcli*}

pacman -U --noconfirm *.xz

#---------------------------------------------------------------------------------
echo -e "\n\e[36[mConfigure ...\e[m\n"

# remove cache and custom package files
rm /var/cache/pacman/pkg/* /root/{*.xz,*.zip} /usr/local/bin/create-*
rm -r /root/armv6h

# RPi 4
if [[ $hwcode == 11 ]]; then
	sed -i '/force_turbo=1/ d' /boot/config.txt
	mv /usr/lib/firmware/updates/brcm/BCM{4345C0,}.hcd
fi

# RPi 4, 3, 2 - boot splash
if echo 04 08 0d 0e 11 | grep -q $hwcode; then
	cmdline='root=/dev/mmcblk0p2 rw rootwait selinux=0 fsck.repair=yes smsc95xx.turbo_mode=N dwc_otg.lpm_enable=0 '
	cmdline+='elevator=noop console=tty3 plymouth.enable=0 quiet loglevel=0 logo.nologo vt.global_cursor_default=0'
	echo $cmdline > /boot/cmdline.txt
fi

# RPi 2, 1, 0 - no onboard wireless
[[ ! $wireless ]] && sed -i '/disable-wifi\|disable-bt/ d' /boot/config.txt

# RPi 0 - fix kernel panic
[[ $hwcode == 09 || $hwcode == 0c ]] && sed -i -e '/force_turbo=1/ i\over_voltage=2' -e '/dtparam=audio=on/ a\hdmi_drive=2' /boot/config.txt

# alsa
chmod -R 666 /var/lib/alsa  # fix permission
sed -i '/^TEST/ s/^/#/' /usr/lib/udev/rules.d/90-alsa-restore.rules   # omit test rules

# boot partition - fix dirty bits if any
fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'

# bluetooth (skip if removed bluetooth)
[[ -e /usr/bin/bluetoothctl ]] && sed -i 's/#*\(AutoEnable=\).*/\1true/' /etc/bluetooth/main.conf

# cron - for addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addons-update.sh &' ) | crontab -

# lvm - remove invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - create missing log file
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# motd - remove default
rm /etc/motd

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

# upmpdcli - fix: missing symlink
[[ -e /usr/bin/upmpdcli ]] && ln -s /lib/libjsoncpp.so.{21,20}

# wireless-regdom
echo 'WIRELESS_REGDOM="00"' > /etc/conf.d/wireless-regdom

# startup services
systemctl daemon-reload

startup='avahi-daemon bootsplash cronie devmon@mpd localbrowser nginx php-fpm startup'

if [[ -e /usr/bin/chromium ]]; then
    # bootsplash - set default image
    ln -s /srv/http/assets/img/{NORMAL,start}.png
    
    # login prompt - remove
    systemctl disable getty@tty1
else
    startup=${startup/bootsplash }
    startup=${startup/localbrowser }
fi

[[ ! -e /usr/bin/avahi-daemon ]] && startup=${startup/avahi-daemon }

systemctl enable $startup

#---------------------------------------------------------------------------------
echo -e "\n\e[m36Default settings ...\e[m\n"

# data - settings directories
dirdata=/srv/http/data
dirdisplay=$dirdata/display
dirsystem=$dirdata/system
mkdir "$dirdata"
for dir in addons bookmarks coverarts display gpio lyrics mpd playlists sampling system tmp webradios; do
	mkdir "$dirdata/$dir"
done
# addons
echo $addoversion > /srv/http/data/addons/rr$version
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

# mpd - music directories
mkdir -p /mnt/MPD/{NAS,SD,USB}

# set permissions and ownership
chown -R http:http "$dirdata"
chown -R mpd:audio "$dirdata/mpd" /mnt/MPD

echo -e "\n\e[36mRuneAudio+Re created successfully.\e[m\n"
hr
