RuneOS
---
- Build RuneAudio+R from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Download and write to `ROOT` and `BOOT` partitions
- Start Arch Linux Arm
- Upgrade to latest kernel and packages
- Install packages
- Download web interface, custom packages and config files
- Install custom packages
- Set configurations

**Need**
- Linux PC (or Linux in VirtualBox on Windows with network set as `Bridge Adapter`)
- Raspberry Pi
- Wired LAN connection (if not available, monitor + keyboard)
- Normal SD mode
	- Micro SD card - 4GB+ - `BOOT` + `ROOT` partitions
- USB mode - `ROOT` partition on USB drive (for hard drive or fast thumb drive)
	- Micro SD card - 100MB+ - `BOOT` partition only
	- USB drive - 4GB+ - `ROOT` partition (or existing USB hard drive with data)
---

**Download Arch Linux Arm**

| Model        | SoC       | File                             |
|--------------|-----------|----------------------------------|
| RPi Z, A, B  | BCM2835   | ArchLinuxARM-rpi-latest.tar.gz   |
| RPi 2B, 3B   | BCM2837   | ArchLinuxARM-rpi-2-latest.tar.gz |
| RPi 3A+, 3B+ | BCM2837B0 | ArchLinuxARM-rpi-3-latest.tar.gz |
| RPi 4B       | BCM2711   | ArchLinuxARM-rpi-4-latest.tar.gz |

- On Linux PC (Copy > paste unless corrections needed)
```sh
su

# download - replace with matched model
file=ArchLinuxARM-rpi-2-latest.tar.gz

### download ### -----------------------------------
# if downlod is too slow, ctrl+c > rm $file and try again
wget -qN --show-progress http://os.archlinuxarm.org/os/$file

# install packages (skip if already installed)
apt install bsdtar nmap  # arch linux: pacman -S bsdtar nmap

# function for verify names
cols=$( tput cols )
showData() {
    printf %"$cols"s | tr ' ' -
    echo $1
    echo $2
    printf %"$cols"s | tr ' ' -
}
```

**Prepare partitions**
- SD card mode (normal)
	- Insert Micro SD card
	- Create partitions with **GParted**

| Type    | No. | Label* | Format | Size       |
|---------|-----|--------|--------|------------|
| primary | #1  | BOOT   | fat32  | 100MB      |
| primary | #2  | ROOT   | ext4   | (the rest) |
	
- USB drive mode (run RuneAudio+R from USB drive)
	- Insert Micro SD card
		- Format to `fat32` and label as `BOOT`
	- Plug in USB drive
		- Blank:
			- Format: `ext4`
			- Label: `ROOT`
		- With existing data:
			- No need to change format of existing partition
			- Resize and create a new 4GB partition (anywhere - at the end, middle or start of the disk)
			- Format: `ext4`
			- Label: `ROOT`

**Write `ROOT` partition**
- Click `BOOT` and `ROOT` in **Files** to mount
```sh
# get ROOT partition and verify
ROOT=$( df | grep ROOT | awk '{print $NF}' )
showData "$( df -h | grep ROOT )" "ROOT = $ROOT"

### expand to usb drive ### -----------------------------------
bsdtar xpvf $file -C $ROOT  # if errors - install missing packages

# delete downloaded file
rm $file
```

**Write `BOOT` partition**
```sh
# get BOOT partition and verify
BOOT=$( df | grep BOOT | awk '{print $NF}' )
showData "$( df -h | grep BOOT )" "BOOT = $BOOT"

mv -v $ROOT/boot/* $BOOT 2> /dev/null
```

**Setup USB as root partition** (Skip if SD card mode)
```sh
# get UUID and verify
dev=$( df | grep ROOT | awk '{print $1}' )
uuid=$( /sbin/blkid | grep $dev | cut -d' ' -f3 | tr -d '"' )
showData "$( df -h | grep ROOT )" $uuid

# replace root device
sed -i "s|/dev/mmcblk0p2|$uuid|" $BOOT/cmdline.txt

# append to fstab
echo "$uuid  /  ext4  defaults  0  0" >> $ROOT/etc/fstab
```

**Unmount and remove**
```sh
umount -l $BOOT
umount -l $ROOT
```

**Start Arch Linux Arm**
- Remove all USB devices: drives, Wi-Fi, bluetooth, mouse
- Connect wired LAN (if not available, connect monitor + keyboard)
- Insert the micro SD card in RPi
- If USB mode, plugin the USB drive
- Power on
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

ssh-keygen -R $rpiip  # remove existing key if any

ssh alarm@$rpiip  # password: alarm
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
packages='alsa-utils avahi bluez bluez-utils chromium cronie dnsmasq dosfstools ffmpeg gcc hostapd '
packages+='ifplugd imagemagick mpd mpc nfs-utils nss-mdns ntfs-3g parted php-fpm python python-pip '
packages+='samba shairport-sync sudo udevil wget xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit'
```

**Exclude for hardware support** (Skip if RPi3, 4)
```sh
# RPi 1, Zero (single core CPU) - no browser on rpi
packages=${packages/ chromium}
packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}

model=$( cat /proc/cpuinfo | grep Revision | tail -c 4 | cut -c 1-2 )
echo 00 01 02 03 04 09 | grep -q $model && nowireless=1 || nowireless=

# (skip for generic build) remove bluetooth if not RPi Zero W, 3, 4
[[ $nowireless ]] && packages=${packages/ bluez bluez-utils}
```

**Exclude optional packages** (Skip to install all)
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
### install packages ### -----------------------------------
pacman -S $packages

# start systemd-random-seed (fix - Kernel entropy pool is not initialized)
systemctl start systemd-random-seed

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
- `runonce.sh` for initial boot setup
```sh
### download ### -----------------------------------
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip

bsdtar xvf *.zip --strip 1 --exclude=.* --exclude=*.md -C /

chmod -R 755 /srv/http /usr/local/bin
chown -R http:http /srv/http

# skip for generic build
[[ $nowireless ]] && rm bluealsa*
```

**Exclude optional packages** (Skip to install all)
```sh
# remove bluetooth
rm -f bluealsa*

# remove metadata tag editor
rm kid3-cli*

# remove UPnP
rm libupnpp* upmpdcli*
```

**Exclude removed packages configurations** (Skip if install all)
```sh
[[ ! -e /usr/bin/avahi-daemon ]] && rm -r /etc/avahi/services
if [[ ! -e /usr/bin/chromium ]]; then
    rm libmatchbox* matchbox*
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
### install custom packages ### -----------------------------------
pacman -U *.pkg.tar.xz

# remove cache and custom package files
rm /var/cache/pacman/pkg/* *.pkg.tar.xz *.zip
```

**Migrate existing database and settings** (Skip if not available)
- Copy `data` directory to `/srv/http`

**Configurations**
```sh
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

# initialize / restore settings
runeinit.sh
```

**Finish**
```sh
reboot
```
---

**To reset database and all settings**
```sh
runereset.sh
shutdown -r now
```

**To reimport existing database and settings**
```sh
rm -r /srv/http/data
```
- Copy `data` directory to `/srv/http`
```sh
runeinit.sh
shutdown -r now
```

**Optional - Create image file**
- Once start RuneAudio+R successfully, Power > Off
- Move micro SD card (and the USB drive, if `ROOT` partition is in USB drive) to PC
- Resize `ROOT` partition to smallest size possible with **GParted**.
	- menu: GParted > Devices > /dev/sd?
	- right-click `ROOT` partiton > Unmount
	- right-click `ROOT` partiton > Resize/Move
	- drag rigth triangle to fit minimum size
	- menu: Edit > Apply all operations
- Create image - SD card mode
	- on Windows (much faster): [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/) > Read only allocated partitions
	- OR
```sh
# get device and verify
part=$( df | grep BOOT | awk '{print $1}' )
dev=${part:0:-1}
df | grep BOOT
echo device = $dev

# get partition end and verify
fdisk -u -l $dev
end=$( fdisk -u -l $dev | tail -1 | awk '{print $3}' )
echo end = $end

# create image
dd if=$dev of=RuneAudio+Re2.img count=$(( end + 1 )) status=progress  # remove status=progress if errors
```
- Create image - USB drive mode
	- With **Disks**: select drive > select partition > cogs button > Create Partition Image
