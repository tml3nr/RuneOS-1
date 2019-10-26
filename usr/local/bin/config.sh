#!/bin/bash

# alsa
chmod -R 666 /var/lib/alsa  # fix permission
sed -i '/^TEST/ s/^/#/' /usr/lib/udev/rules.d/90-alsa-restore.rules   # omit test rules

# bluetooth (skip if removed bluetooth)
if [[ -e /usr/bin/bluetoothctl ]]; then
    sed -i 's/#*\(AutoEnable=\).*/\1true/' /etc/bluetooth/main.conf
    [[ $model == 11 ]] && mv /usr/lib/firmware/updates/brcm/BCM{4345C0,}.hcd
fi

# cron - for addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addons-update.sh &' ) | crontab -

# lvm - remove invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - music directories
mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# mpd - create missing log file
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# motd - remove default
rm /etc/motd

# nginx - custom 50x.html
mv -f /etc/nginx/html/50x.html{.custom,}

# password - set default
echo root:rune | chpasswd

# ssh - permit root
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# upmpdcli - initialize key and fix missing symlink (skip if removed UPnP)
if [[ -e /usr/bin/upmpdcli ]]; then
    upmpdcli -c /etc/upmpdcli.conf &> /dev/null &
    ln -s /lib/libjsoncpp.so.{21,20}
fi

# user - set expire to none
users=$( cut -d: -f1 /etc/passwd )
for user in $users; do
    chage -E -1 $user
done

# wireless-regdom
sed -i '/WIRELESS_REGDOM="00"/ s/^#//' /etc/conf.d/wireless-regdom

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

# fix sd card dirty bits if any
fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'

rm $0
