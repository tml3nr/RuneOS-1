ArchLinuxArm
---

On Linux

**Partition SD Card**
- Gparted

| Type    | No. | Label | Format | Size     |
|---------|-----|-------|--------|----------|
| primary | #1  | BOOT  | fat32  | 100MB    |
| primary | #2  | ROOT  | ext4   | the rest |

**Download**
- list: https://archlinuxarm.org/about/downloads
```sh
# get user
whoami

sudo su
user=<user> # from previous command

# download
#file=ArchLinuxARM-rpi-4-latest.tar.gz  # RPi4
#file=ArchLinuxARM-rpi-3-latest.tar.gz  # RPi3B+
file=ArchLinuxARM-rpi-2-latest.tar.gz   # RPi2, RPi3
wget http://os.archlinuxarm.org/os/$file
```

### Flash SD card
```sh
# install bsdtar ("tar" will show lots of errors.)
apt install bsdtar

# extract
bsdtar xpvf $file -C /media/$user/ROOT
cp -rv --no-preserve=mode,ownership /media/$user/ROOT/boot/* /media/$user/BOOT
rm -r /media/$user/ROOT/boot/*
```

### Boot
- SCP/SSH with user|password : alarm|alarm
```sh
# set root's password to "rune"
su # password: root
passwd

# permit root SSH login
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl reload sshd

# initialize pgp key (May have to wait for "haveged" to make enough entropy.)
pacman-key --init
pacman-key --populate archlinuxarm

# Or temporarily bypass key verifications
#sed -i '/^SigLevel/ s/^/#/; a\SigLevel    = TrustAll' /etc/pacman.conf
```

### Install packages
```sh
# full upgrade
pacman -Syu

# packages
pacman -S alsa-utils avahi chromium dosfstools dnsmasq ffmpeg gcc hostapd ifplugd mpd mpc parted php-fpm samba shairport-sync sudo udevil wget xirg-server xorg-xinit xf86-video-fbdev xf86-video-vesa
#cifs-utils nfs-utils

# python (optional)
pacman -S  python python-pip
pip install RPi.GPIO

# fix - mpd - log
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# fix - avahi - Failed to open /etc/resolv.conf + chroot.c: open() failed
sed -i '/Requires/ a\After=systemd-resolved.service' /usr/lib/systemd/system/avahi-daemon.service

# fix - lvm - Invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules
```

### Custom packages
- Not support some features
	- `nginx-mainline` - pushstream
- AUR only (Not available as standard packages)
	- `kid3-cli`
	- `matchbox-window-manager`
	- `upmpdcli`
```sh
# custom packages and config files
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf master.zip --strip 1 --exclude=.* --exclude=*.md -C /
chmod -R 755 /srv/http /usr/local/bin
chown -R http:http /srv/http

# install custom packages
pacman -U *.pkg.tar.xz
rm *.pkg.tar.xz

# fixes
mkdir -p /var/lib/nginx/client-body  # fix - no directory found
ln -s /lib/libjsoncpp.so.{21,20}     # fix - older link

# enable startup services
systemctl daemon-reload
systemctl enable avahi-daemon bootsplash devmon@root nginx php-fpm startup
```

### Configurations
```sh
# set hostname
hostname runeaudio
echo runeaudio > /etc/hostname

# mpd directories
mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# cron addons updates ( &> /dev/null suppress 1st crontab -l > no entries yet )
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addonsupdate.sh &' ) | crontab -

# motd
rm /etc/motd

# bootsplash
ln -s /srv/http/assets/img/{NORMAL,start}.png
```
