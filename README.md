RuneOS
---
- For all Raspberry Pi: 0, 1, 2, 3 and 4 (3A+ and 3B+: not yet tested but should work)
- Build RuneAudio+R from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Download and write to `ROOT` and `BOOT` partitions
- Start Arch Linux Arm
- (Optional) Pre-configure Wi-Fi connection for headless(no monitor) system
- Upgrade to latest kernel and packages
- Install packages
- Download web interface, custom packages and config files
- Install custom packages
- Configure settings

**Need**
- Linux PC (or Linux in VirtualBox on Windows with network set as `Bridge Adapter`)
	- GParted and Files app (normally already installed)
	- Basic skill of terminal command line
- Raspberry Pi
- Network connection
	- Wired LAN (more stable)
	- Wi-Fi connection
- Normal SD mode
	- Micro SD card - 4GB+ - `BOOT` + `ROOT` partitions
- USB mode (for hard drive or fast thumb drive)
	- Micro SD card - 100MB+ - `BOOT` partition only
	- USB drive - 4GB+ - `ROOT` partition (or existing USB hard drive with data)
---

### Build

- On Linux PC
	- Command lines - gray code blocks
	- Copy-paste unless corrections needed
	- Comments - Lines with leading `#` can be skipped.

**Prepare partitions**
- SD card mode (normal)
	- Insert micro SD card
	- Delete all partitions (make sure it's the micro SD card)
	- Create partitions with **GParted** app

| No. | Size        | Type    | Format | Label |
|-----|-------------|---------|--------|-------|
| #1  | 100MiB      | primary | fat32  | BOOT  |
| #2  | (the rest)  | primary | ext4   | ROOT  |
	
- USB drive mode (run RuneAudio+R from USB drive)
	- Insert Micro SD card
		- Delete all partitions (make sure it's the micro SD card)
		- Format: `fat32`
		- Label: `BOOT`
	- Plug in USB drive
		- Blank:
			- Delete all partitions (Caution: make sure it's the USB drive)
			- Format: `ext4`
			- Label: `ROOT`
		- With existing data:
			- No need to reformat or change format of existing partition
			- Resize the existing to get 4GB unallocated space (anywhere - at the end, middle or start of the disk)
			- Create a new partition in the new 4GB space
				- Format: `ext4`
				- Label: `ROOT`

**Download and write `BOOT` and `ROOT`**
```sh
# switch user to root
su -

# write script
wget -qN --show-progress https://github.com/rern/RuneOS/raw/master/usr/local/bin/write-alarm.sh
chmod +x write-alarm.sh
./write-alarm.sh
```
- If downlod is too slow, `Ctrl+C` > `wget ...` again

**Start Arch Linux Arm**
- Move micro SD card (and USB drive if in USB drive mode) to RPi
- Plug in wired LAN (RPi without wired LAN or Wi-Fi - plug in USB Wi-Fi)
- Remove all other USB devices if any
- Power on
- Wait 30 seconds

▼ skip if already known IP ▼ **Get IP address of RPi**
```sh
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap -sP ${routerip%.*}.*
```
- If RPi not show up in result:
	- RPi 4 may listed as unknown
	- Plugin wired LAN and `nmap ...` again
	- Still not found, connect a monitor/tv and start over again

**Connect PC to RPi**
```sh
# set ip
read -r -p "RPi IP: " rpiip; echo

# remove existing key if any
ssh-keygen -R $rpiip 2> /dev/null

# connect
ssh alarm@$rpiip  # confirm: yes > password: alarm
```

**Initialize and upgrade**
```sh
# switch user to root
su # password: root

# change directory to root
cd

# initialize pgp key
pacman-key --init
pacman-key --populate archlinuxarm

# fill entropy pool (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

# fix dns errors
systemctl stop systemd-resolved

# system-wide kernel and packages upgrade
pacman -Syu
# if download is too slow or stuck, Ctrl+C then pacman -Syu again
```

**(Optional)**
- Create image of Arch Linux Arm to skip all previous steps in next rebuild 
	- [Create image file](https://github.com/rern/RuneOS/blob/master/imagefile.md)
	- On rebuild:
		- Write image file to micro SD card
		- `pacman -Syu` then continue

**Packages**
```sh
# package list
packages='alsa-utils avahi bluez bluez-utils chromium cronie dnsmasq dosfstools ffmpeg gcc hostapd '
packages+='ifplugd imagemagick mpd mpc nfs-utils nss-mdns ntfs-3g parted php-fpm python python-pip '
packages+='samba shairport-sync sudo udevil wget xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit'

# get RPi hardware code
hwcode=$( cat /proc/cpuinfo | grep Revision | tail -c 4 | cut -c 1-2 )
echo 00 01 02 03 04 09 | grep -q $hwcode && nobt=1 || nobt=

# ▼ skip if NOT RPi 0, 1 ▼ remove browser on rpi - too much for CPU
if echo 00 01 02 03 04 09 | grep -q $hwcode; then
    packages=${packages/ chromium}
    packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}
fi

# remove bluetooth if not RPi 0 W, 3, 4
[[ $nobt ]] && packages=${packages/ bluez bluez-utils}
```

▼ skip to install all ▼ **Exclude optional packages**
```sh
# remove connect by name: runeaudio.local
packages=${packages/ avahi}

# remove bluetooth support
packages=${packages/ bluez bluez-utils}

# remove access point
packages=${packages/ dnsmasq}
packages=${packages/ hostapd}

# remove airplay
packages=${packages/ shairport-sync}

# remove browser on rpi
packages=${packages/ chromium}
packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}

# remove extended audio format:
#   16sv 3g2 3gp 4xm 8svx aa3 aac ac3 adx afc aif aifc aiff al alaw amr anim apc ape asf atrac au aud avi avm2 avs 
#   bap bfi c93 cak cin cmv cpk daud dct divx dts dv dvd dxa eac3 film flac flc fli fll flx flv g726 gsm gxf iss 
#   m1v m2v m2t m2ts m4a m4b m4v mad mj2 mjpeg mjpg mka mkv mlp mm mmf mov mp+ mp1 mp2 mp3 mp4 mpc mpeg mpg mpga mpp mpu mve mvi mxf 
#   nc nsv nut nuv oga ogm ogv ogx oma ogg omg opus psp pva qcp qt r3d ra ram rl2 rm rmvb roq rpl rvc shn smk snd sol son spx str swf 
#   tak tgi tgq tgv thp ts tsp tta xa xvid uv uv2 vb vid vob voc vp6 vmd wav webm wma wmv wsaud wsvga wv wve
packages=${packages/ ffmpeg}

# remove file sharing
packages=${packages/ samba}

# remove python (to install UPnP, do not remove)
packages=${packages/ python python-pip}
```

**Install packages**
```sh
# install packages
pacman -S $packages # select default

# optional - install RPi.GPIO
pip --no-cache-dir install RPi.GPIO
```

**RuneUI, custom packages and config files**
- RuneAudio Enhancement interface
- Custom packages (not available as standard package)
	- `nginx-mainline-pushstream`
	- `kid3-cli`
	- `matchbox-window-manager`
	- `bluealsa`
	- `upmpdcli`
- Configuration files set to default
- Initialize / restore database and settings
```sh
# get custom packages and setup files
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip

# expand to target directories
bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /
[[ $nobt ]] && rm /root/bluealsa* /root/armv6h/bluealsa* /boot/overlays/bcmbt.dtbo

# set permissions and ownership
chmod 755 /srv/http/* /srv/http/settings/* /usr/local/bin/*
chown -R http:http /srv/http
```

▼ skip to install all ▼ **Exclude optional packages**
```sh
# remove bluetooth
rm -f bluealsa*

# remove metadata tag editor
rm -f kid3-cli*

# remove UPnP
rm -f libupnpp* upmpdcli*
```

▼ skip to install all ▼ **Exclude removed packages configurations**
```sh
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
```

**Install custom packages**
```sh
# install
pacman -U *.pkg.tar.xz

# ▼ skip if removed UPnP ▼ upmpdcli - fix missing symlink and generate RSA private key
if [[ -e /usr/bin/upmpdcli ]]; then
    ln -s /lib/libjsoncpp.so.{21,20}
    mpd --no-config 2> /dev/null
    upmpdcli -c /etc/upmpdcli.conf
fi
# Ctrl+C when 'writing RSA key' shown
```

**Configurations**
```sh
# configure settings
runeconfigure.sh
```

**Finish**
```sh
# reboot
shutdown -r now
```
---

**Setup Wi-Fi auto-connect** (if not set during build)
- On Linux PC
- Insert micro SD card or USB drive with RuneAudio+Re `ROOT` partition
- Open **File** app
- Click `ROOT` to mount
- Hover mouse pointer over ROOT - note path for verification
```sh
wget -qN https://github.com/rern/RuneOS/raw/master/usr/local/bin/wifisetup.sh; chmod +x wifisetup.sh; ./wifisetup.sh
```

**Optional** 
- [Create image file](https://github.com/rern/RuneOS/blob/master/imagefile.md)
