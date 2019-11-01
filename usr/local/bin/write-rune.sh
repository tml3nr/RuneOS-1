#!/bin/bash

echo -e "\nInitialize pgp key ...\n"
pacman-key --init
pacman-key --populate archlinuxarm

# fill entropy pool (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

# fix dns errors
systemctl stop systemd-resolved

echo -e "\nSystem-wide kernel and packages upgrade ...\n"
pacman -Syu --noconfirm --needed

packages='alsa-utils cronie dosfstools gcc ifplugd imagemagick mpd mpc nfs-utils nss-mdns ntfs-3g parted php-fpm python python-pip sudo udevil wget '

# get RPi hardware code
hwcode=$( cat /proc/cpuinfo | grep Revision | tail -c 4 | cut -c 1-2 )
echo 00 01 02 03 04 09 | grep -q $hwcode && nobt=1 || nobt=

read -rn 1 -p "Install all packages [Y/n]: " ans; echo
if [[ $ans == y || $ans == Y ]]; then
    packages+='avahi dnsmasq ffmpeg hostapd python python-pip samba shairport-sync'
    # RPi 0W, 3, 4
    [[ -n $nobt ]] && packages+='bluez bluez-utils '
    # RPi 2, 3, 4
    [[ echo 04 08 0d 0e 11 | grep -q $hwcode ]] && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit '
else
    read -rn 1 -p "Install Avahi - Connect by: runeaudio.local [y/N]: " ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='avahi '
    if [[ -n $nobt ]]; then
        read -rn 1 -p "Install Bluez - Bluetooth supports [y/N]: " blue; echo
        [[ $blue == y || $blue == Y ]] && packages+='bluez bluez-utils '
    fi
    if [[ echo 04 08 0d 0e 11 | grep -q $hwcode ]]; then
        read -rn 1 -p "Install Chromium - Browser on RPi [y/N]: " ans; echo
        [[ $ans == y || $ans == Y ]] && packages+='chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit '
    fi
    read -rn 1 -p "Install FFmpeg - Extended decoder[y/N]: " ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='ffmpeg '
    read -rn 1 -p "Install hostapd - RPi access point [y/N]: " ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='dnsmasq hostapd '
    read -rn 1 -p "Install Samba - File sharing [y/N]: " ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='samba '
    read -rn 1 -p "Install Shairport-sync - AirPlay [y/N]: " ans; echo
    [[ $ans == y || $ans == Y ]] && packages+='shairport-sync '
    
    read -rn 1 -p "Install Kid3 - Metadata tag editor [y/N]: " kid3; echo
    read -rn 1 -p "Install upmpdcli - UPnP [y/N]: " upnp; echo
    if [[ $upnp != y && $upnp != Y ]]; then
        read -rn 1 -p "Install Python [y/N]: " pyt; echo
        if [[ $pyt == y || $pyt == Y ]]; then
            packages+='python python-pip '
            read -rn 1 -p "Install Python pip [y/N]: " pip; echo
        fi
    fi
fi

echo -e "\nInstall packages ...\n"
pacman -S --noconfirm --needed $packages

[[ $pyt == y || $pyt == Y ]] && yes | pip --no-cache-dir install RPi.GPIO

echo -e "\nInstall custom packages and web interface ...\n"
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /

# no onboard wireless
[[ $nobt ]] && rm /root/bluealsa* /root/armv6h/bluealsa* /boot/overlays/bcmbt.dtbo

# RPi 0, 1
if [[ echo 00 01 02 03 09 0c | grep -q $hwcode ]]; then
    rm /root/*.xz
    mv /root/armv6h/* /root
fi

chmod 755 /srv/http/* /srv/http/settings/* /usr/local/bin/*
chown -R http:http /srv/http

[[ $blue != y && $blue != Y ]] && rm /root/blue*
[[ $kid3 != y && $kid3 != Y ]] && rm /root/kid3*
[[ $upnp != y && $upnp != Y ]] && rm /root/{libupnpp*,upmpdcli*}

# remove config of excluded packages
[[ ! -e /usr/bin/avahi-daemon ]] && rm -r /etc/avahi/services
if [[ ! -e /usr/bin/chromium ]]; then
    rm -f libmatchbox* matchbox*
    rm /etc/systemd/system/localbrowser*
    rm /etc/X11/xinit/xinitrc
fi
[[ ! -e /usr/bin/bluetoothctl ]] && rm -r /etc/systemd/system/bluetooth.service.d
[[ ! -e /usr/bin/hostapd ]] && rm -r /etc/{hostapd,dnsmasq.conf}
[[ ! -e /usr/bin/smbd ]] && rm -r /etc/samba
[[ ! -e /usr/bin/shairport-sync ]] && rm /etc/systemd/system/shairport*

pacman -U --noconfirm *.xz

runeconfigure.sh
