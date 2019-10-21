RuneOS
---
Build RuneAudio+R from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) releases to run on USB drive (+ microSD card)
- Download and write to USB drive and SD card
- Start Arch Linux Arm
- Upgrade to latest kernel and packages
- Install packages
- Download web interface, custom packages and config files
- Install custom packages
- Fix and set configurations
- Create image file

**Need**
- Linux PC (or Linux in VirtualBox on Windows)
- Raspberry Pi
- USB drive - 4GB+ for root partition (or existing USB hard drive with data)
- Micro SD card - 100MB+ (not GB) for boot partition
- wired LAN connection (if not available, monitor + keyboard)
<hr>

**Download Arch Linux Arm**
- On Linux PC
```sh
su

branch=usb

# download
#file=ArchLinuxARM-rpi-4-latest.tar.gz  # RPi4
#file=ArchLinuxARM-rpi-3-latest.tar.gz  # RPi3B+
#file=ArchLinuxARM-rpi-2-latest.tar.gz  # RPi2, RPi3
#file=ArchLinuxARM-rpi-latest.tar.gz    # RPi1, RPi Zero

# replace with required version
file=ArchLinuxARM-rpi-2-latest.tar.gz

### download ### -----------------------------------
wget http://os.archlinuxarm.org/os/$file
```

**Write to USB drive**
- Plug in USB drive
	- Blank:
		- Format: `ext4`
		- Label: `ROOT`
	- With existing data:
		- No need to change format of existing partition
		- Resize and create a new 4GB partition
		- Format: `ext4`
		- Label: `ROOT`
- Click `ROOT` in **Files** to mount
```sh
# install bsdtar and nmap
apt install bsdtar nmap

# function for verify names
cols=$( tput cols )
showData() {
	printf %"$cols"s | tr ' ' -
	echo $1
	echo $2
	printf %"$cols"s | tr ' ' -
}

# get partition and verify
ROOT=$( df | grep ROOT | awk '{print $NF}' )
showData "$( df -h | grep ROOT )" "ROOT = $ROOT"

### expand to usb drive ### -----------------------------------
bsdtar xpvf $file -C $ROOT  # if errors - install missing package

# delete downloaded file
rm $file
```

**Move `/boot/*` to SD card**
- Insert Micro SD card
- Format to `fat32` and labeled `BOOT`
- Click it in Files/Nautilus to mount.
```sh
# get partition and verify
BOOT=$( df | grep BOOT | awk '{print $NF}' )
showData "$( df -h | grep BOOT )" "BOOT = $BOOT"

mv -v $ROOT/boot/* $BOOT 2> /dev/null

# replace cmdline.txt and config.txt
wget https://github.com/rern/RuneOS/raw/$branch/cmdline.txt -O $BOOT/cmdline.txt
wget https://github.com/rern/RuneOS/raw/$branch/config.txt -O $BOOT/config.txt
```

**Setup USB as root partition**
```sh
# get UUID and verify
dev=$( df | grep ROOT | awk '{print $1}' )
uuid=$( /sbin/blkid | grep $dev | cut -d' ' -f3 | tr -d '"' )
showData "$( df -h | grep ROOT )" $uuid

# replace root device
sed -i "s|/dev/mmcblk0p2|$uuid|" $BOOT/cmdline.txt

# append to fstab
echo "$uuid  /  ext4  defaults  0  0" >> $ROOT/etc/fstab

# unmount usb drive and sd card
umount -l $BOOT
umount -l $ROOT
```

**Start Arch Linux Arm**
- Remove all USB devices: drives, Wi-Fi, bluetooth, mouse
- Connect wired LAN (if not available, connect monitor + keyboard)
- Move USB drive and micro SD card to RPi
- Power on / connect RPi power
- Wait 30 seconds (or login prompt on connected monitor)

**Connect PC to RPi** (skip for connected monitor + keyboard) 
```sh
# get RPi IP address and verify - skip to ### connect ### for known IP
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap=$( nmap -sP ${routerip%.*}.* | grep -B2 Raspberry )
rpiip=$( echo "$nmap" | head -1 | awk '{print $NF}' | tr -d '()' )
showData "$nmap" "RPi IP = $rpiip"

### connect ### -----------------------------------
# already known IP or if there's more than 1 RPi, set rpiip manually
# rpiip=<IP>

ssh alarm@$rpiip  # password: alarm

# if WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! - remove existing key
ssh-keygen -R $rpiip
```
- If `ssh` failed, start all over again. (A lot of `[FAILED]` on connected monitor.)


**Packages**
```sh
# switch user to root
su # password: root

# change directory to root
cd

# initialize pgp key
pacman-key --init
pacman-key --populate archlinuxarm

### full system-wide upgrade ### -----------------------------------
pacman -Syu

# package list
packages='alsa-utils avahi bluez bluez-utils chromium cronie dnsmasq dosfstools exfat-utils ffmpeg gcc '
packages+='hostapd ifplugd imagemagick mpd mpc nfs-utils ntfs-3g parted php-fpm python python-pip '
packages+='samba shairport-sync sudo udevil wget xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit'
```

**Exclude for hardware support** (Skip if RPi3, 4)
```sh
hwrev=$( cat /proc/cpuinfo | grep Revision | tail -c 3 )

# remove bluetooth if not RPi Zero W, 3, 4
[[ $hwrev != c1 && $hwrev != 82 && $hwrev != 11 ]] && nowireless=1 || nowireless=
[[ $nowireless ]] && packages=${packages/ bluez bluez-utils}

# RPi Zero, 1 - no browser on rpi
if [[ $hwrev == 92 || $hwrev == 93 || $hwrev == c1 || $hwrev == 32 || $hwrev == 21 ]]; then
	packages=${packages/ chromium}
	packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}
fi
```

**Exclude optional packages** (Skip to install all)
```sh
# optional - remove bluetooth support
packages=${packages/ bluez bluez-utils}

# optional - remove access point
packages=${packages/ dnsmasq}
packages=${packages/ hostapd}

# optional - remove airplay
packages=${packages/ shairport-sync}

# optional - remove browser on rpi
packages=${packages/ chromium}
packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}

# optional - remove extended audio format:
#   16sv 3g2 3gp 4xm 8svx aa3 aac ac3 adx afc aif aifc aiff al alaw amr anim apc ape asf atrac au aud avi avm2 avs 
#   bap bfi c93 cak cin cmv cpk daud dct divx dts dv dvd dxa eac3 film flac flc fli fll flx flv g726 gsm gxf iss 
#   m1v m2v m2t m2ts m4a m4b m4v mad mj2 mjpeg mjpg mka mkv mlp mm mmf mov mp+ mp1 mp2 mp3 mp4 mpc mpeg mpg mpga mpp mpu mve mvi mxf 
#   nc nsv nut nuv oga ogm ogv ogx oma ogg omg opus psp pva qcp qt r3d ra ram rl2 rm rmvb roq rpl rvc shn smk snd sol son spx str swf 
#   tak tgi tgq tgv thp ts tsp tta xa xvid uv uv2 vb vid vob voc vp6 vmd wav webm wma wmv wsaud wsvga wv wve
packages=${packages/ ffmpeg}

# optional - remove file sharing
packages=${packages/ samba}

# optional - remove python (to install UPnP, do not remove)
packages=${packages/ python python-pip}
```

**Install packages**
```sh
### install packages ### -----------------------------------
pacman -S $packages

# start systemd-random-seed (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

# optional - install RPi.GPIO
pip --no-cache-dir install RPi.GPIO

# remove cache
rm /var/cache/pacman/pkg/*
```

**Web interface, custom packages and config files**
- RuneAudio Enhancement interface
- Custom packages (not available as standard package)
	- `nginx-mainline-pushstream`
	- `kid3-cli`
	- `matchbox-window-manager`
	- `bluealsa`
	- `upmpdcli`
- Configuration files set to default
- `runonce.sh` for initial boot setup
```sh
### download ### -----------------------------------
wget -q --show-progress https://github.com/rern/RuneOS/archive/$branch.zip
bsdtar xvf $branch.zip --strip 1 --exclude=.* --exclude=*.md --exclude=*.txt -C /
rm $branch.zip
chmod -R 755 /srv/http /usr/local/bin
chown -R http:http /srv/http

[[ $nowireless ]] && rm bluealsa*  # remove bluetooth if not RPi Zero W, 3, 4
```

**Exclude optional packages** (Skip to install all)
```sh
# remove bluetooth
rm -f bluealsa*

# optional - remove metadata tag editor
rm kid3-cli*

# optional - remove UPnP
rm libupnpp* upmpdcli*
```

**Exclude removed packages configurations** (Skip if install all)
```sh
if [[ ! -e /usr/bin/chromium ]]; then
	rm libmatchbox* matchbox*
	rm /etc/systemd/system/localbrowser*
	rm /etc/X11/xinit/xinitrc
fi
[[ ! -e /usr/bin/bluetoothctl || $nowireless ]] && rm -r /etc/systemd/system/bluetooth.service.d
[[ ! -e /usr/bin/hostapd ]] && rm -r /etc/{hostapd,dnsmasq.conf}
[[ ! -e /usr/bin/smbd ]] && rm -r /etc/samba
[[ ! -e /usr/bin/shairport-sync ]] && rm /etc/systemd/system/shairport*
```

**Install custom packages**
```sh
### install custom packages ### -----------------------------------
pacman -U *.pkg.tar.xz
rm *.pkg.tar.xz
```

**Fixes**
```sh
# account expired
users=$( cut -d: -f1 /etc/passwd )
for user in $users; do
	chage -E -1 $user
done

# missing rpi4 bluetooth
[[ $hwrev == 11 ]] && ln -s /usr/lib/firmware/updates/brcm/BCM{4345C0,}.hcd

# lvm - Invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - file not found
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# udev rules - alsa restore failed
sed -i '/^TEST/ s/^/#/' /usr/lib/udev/rules.d/90-alsa-restore.rules

# upmpdcli - older symlink
[[ -e /usr/bin/hostapd ]] && ln -s /lib/libjsoncpp.so.{21,20}
```

**Configurations**
```sh
# bootsplash - set default image
ln -s /srv/http/assets/img/{NORMAL,start}.png

# bluetooth
[[ -e /usr/bin/bluetoothctl ]] && sed -i 's/#*\(AutoEnable=\).*/\1true/' /etc/bluetooth/main.conf

# cron - for addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addonsupdate.sh &' ) | crontab -

# hostname - set default
echo runeaudio > /etc/hostname

# login prompt - remove
systemctl disable getty@tty1

# mpd - music directories
mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# motd - remove default
rm /etc/motd

# nginx - custom 50x.html
mv -f /etc/nginx/html/50x.html{.custom,}

# ntp - set default
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf

# password - set default
echo root:rune | chpasswd

# ssh - permit root
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# timezone - set default
timedatectl set-timezone UTC

# wireless-regdom
sed -i '/WIRELESS_REGDOM="00"/ s/^#//' /etc/conf.d/wireless-regdom

# initialize some services
systemctl daemon-reload
upmpdcli -c /etc/upmpdcli.conf &> /dev/null &  # upmpdcli - write key

# startup services
startup='avahi-daemon bootsplash cronie devmon@mpd localbrowser nginx php-fpm runonce'
[[ ! -e /usr/bin/chromium ]] && ${startup/ localbrowser}
systemctl enable $startup

# fix sd card dirty bits if any
fsck.fat -trawl /dev/mmcblk0p1 | grep -i 'dirty bit'
```

**Finish**
```sh
# if there's existing database and settings directory `data`, copy to:
echo $ROOT/srv/http

reboot
```
