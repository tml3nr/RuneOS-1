#!/bin/bash

echo -e "\n\e[36mInitialize PGP key ...\e[m\n"
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
echo 00 01 02 03 04 09 | grep -q $hwcode && nobt=1 || nobt=

read -ren 1 -p $'Install \e[36mall packages\e[m [y/n]: ' ans; echo
if [[ $ans == y || $ans == Y ]]; then
    packages+='avahi dnsmasq ffmpeg hostapd python python-pip samba shairport-sync '
    # RPi 0W, 3, 4
    [[ -n $nobt ]] && packages+='bluez bluez-utils '
    # RPi 2, 3, 4
    echo 04 08 0d 0e 11 | grep -q $hwcode && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit '
else
    read -ren 1 -p $'Install \e[36mAvahi\e[m - Connect by: runeaudio.local [y/n]: ' ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='avahi '
    if [[ -n $nobt ]]; then
        read -ren 1 -p $'Install \e[36mBluez\e[m - Bluetooth supports [y/n]: ' blue; echo
        [[ $blue == y || $blue == Y ]] && packages+='bluez bluez-utils '
    fi
    if echo 04 08 0d 0e 11 | grep -q $hwcode; then
        read -ren 1 -p $'Install \e[36mChromium\e[m - Browser on RPi [y/n]: ' ans; echo
        [[ $ans == y || $ans == Y ]] && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit '
    fi
    read -ren 1 -p $'Install \e[36mFFmpeg\e[m - Extended decoder[y/n]: ' ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='ffmpeg '
    read -ren 1 -p $'Install \e[36mhostapd\e[m - RPi access point [y/n]: ' ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='dnsmasq hostapd '
    read -ren 1 -p $'Install \e[36mKid3\e[m - Metadata tag editor [y/n]: ' kid3; echo
	read -ren 1 -p $'Install \e[36mPython\e[m - programming language [y/n]: ' pyt; echo
    [[ $pyt == y || $pyt == Y ]] && packages+='python python-pip '
    read -ren 1 -p $'Install \e[36mSamba\e[m - File sharing [y/n]: ' ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='samba '
    read -ren 1 -p $'Install \e[36mShairport-sync\e[m - AirPlay [y/n]: ' ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='shairport-sync '
    read -ren 1 -p $'Install \e[36mupmpdcli\e[m - UPnP [y/n]: ' upnp; echo
fi

echo -e "\n\e[36mInstall packages ...\e[m\n"
pacman -S --noconfirm --needed $packages
[[ $pyt == y || $pyt == Y ]] && yes | pip --no-cache-dir install RPi.GPIO

echo -e "\n\e[36mInstall custom packages and web interface ...\e[m\n"
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /

# no onboard wireless
[[ $nobt ]] && rm /root/bluealsa* /root/armv6h/bluealsa* /boot/overlays/bcmbt.dtbo

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

runeconfigure.sh

echo -e "\n\e[36mDone\e[m\n"
