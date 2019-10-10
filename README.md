RuneOS
---
**Need**
- Linux PC
- Micro SD card - 4GB+
- USB thumb drive - 1GB+

**Arch Linux Arm** https://archlinuxarm.org/about/downloads
```sh
sudo su

# download - uncomment a version
#file=ArchLinuxARM-rpi-4-latest.tar.gz  # RPi4
#file=ArchLinuxARM-rpi-3-latest.tar.gz  # RPi3B+
#file=ArchLinuxARM-rpi-2-latest.tar.gz  # RPi2, RPi3
#file=ArchLinuxARM-rpi-latest.tar.gz    # RPi1, RPi Zero
wget http://os.archlinuxarm.org/os/$file
```

**Write to SD card**
- Create partitions
	- GUI - Gparted or
	- CLI - `fdisk` + `fatlabel` + `e2label`

| Type    | No. | Label* | Format | Size     |
|---------|-----|--------|--------|----------|
| primary | #1  | BOOT   | fat32  | 100MB    |
| primary | #2  | ROOT   | ext4   | the rest |

\* **Label** - Important

```sh
# install bsdtar and nmap
apt install bsdtar namp

# expand to sd card
ROOT=$( df | grep ROOT | awk '{print $NF}' )
BOOT=$( df | grep BOOT | awk '{print $NF}' )
bsdtar xpvf $file -C $ROOT
cp -rv --no-preserve=mode,ownership $ROOT/boot/* $BOOT
rm -r $ROOT/boot/*
```

**Boot**
- Remove all USB drives
- Insert the SD card
- Connect wired LAN
- Power on

**Connect PC to RPi**
```sh
# get RPi IP address
routerip=$( ip route get 1 | cut -d' ' -f3 )
rpiip=$( nmap -sP ${routerip%.*}.* | grep -B2 Raspberry | head -1 | awk '{print $NF}' )

# if there's more than 1 RPi, set rpiip manually
# nmap -sP ${routerip%.*}.* | grep -B2 Raspberry
# rpiip=<ip>

# connect
ssh alarm@$rpiip  password: alarm
```

**Packages**
```sh
su  # password: root

# initialize pgp key
pacman-key --init
pacman-key --populate archlinuxarm

# if errors occured, temporarily bypass key verifications
# sed -i '/^SigLevel/ s/^/#/; a\SigLevel    = TrustAll' /etc/pacman.conf

# full upgrade
pacman -Syu

# packages
pacman -S alsa-utils avahi dosfstools dnsmasq ffmpeg gcc hostapd ifplugd mpd mpc nfs-utils parted php-fpm samba shairport-sync sudo udevil wget

# chromium - optional for browser on rpi
pacman -S chromium xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit

# python - optional for any python scripts (python3)
pacman -S python python-pip
pip install RPi.GPIO
```

**Custom packages**
- Not support some features
	- `nginx-mainline` - pushstream
- AUR only (Not available as standard packages)
	- `kid3-cli`
	- `matchbox-window-manager`
	- `upmpdcli`
	- `ply-image` (single binary file)
```sh
# custom packages and config files
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf master.zip --strip 1 --exclude=.* --exclude=*.md -C /
chmod -R 755 /srv/http /usr/local/bin
chown -R http:http /srv/http

# install custom packages
pacman -U *.pkg.tar.xz
rm *.pkg.tar.xz
```

**Fixes**
```sh
# alsa - Process '/usr/bin/alsactl restore 0' failed
chmod -R 666 /var/lib/alsa
# alsactl store

# avahi - Failed to open /etc/resolv.conf + chroot.c: open() failed
sed -i '/Requires/ a\After=systemd-resolved.service' /usr/lib/systemd/system/avahi-daemon.service

# lvm - Invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - file not found
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# upmpdcli - older symlink
ln -s /lib/libjsoncpp.so.{21,20}
```

**Configurations**
```sh
# bootsplash
ln -s /srv/http/assets/img/{NORMAL,start}.png

# cron - addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addonsupdate.sh &' ) | crontab -

# hostname
echo runeaudio > /etc/hostname

# mpd directories
mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# motd
rm /etc/motd

# ntp
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf

# root's password
passwd  # new password: rune

# root's ssh
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
```

**Startup services**
```sh
systemctl daemon-reload
systemctl enable avahi-daemon bootsplash devmon@root nginx php-fpm startup
```

**Reboot**
- Plug in the USB drive. **Warning** All data in this drive will be deleted.
```sh
# format usb drive
umount -l /dev/sda1
mkfs.ext4 -n thumb /dev/sda1

# reboot
shutdown -r now
```
