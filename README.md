RuneOS
---
Build RuneAudio+R from [Arch Linux Arm](https://archlinuxarm.org/about/downloads) source

**Need**
- Linux PC (or Linux in VirtualBox on Windows)
- Micro SD card - 4GB+
- Card reader

**Arch Linux Arm**
```sh
sudo su

# download
#file=ArchLinuxARM-rpi-4-latest.tar.gz  # RPi4
#file=ArchLinuxARM-rpi-3-latest.tar.gz  # RPi3B+
#file=ArchLinuxARM-rpi-2-latest.tar.gz  # RPi2, RPi3
#file=ArchLinuxARM-rpi-latest.tar.gz    # RPi1, RPi Zero

# replace with required version
file=ArchLinuxARM-rpi-2-latest.tar.gz
wget http://os.archlinuxarm.org/os/$file
```

**Write to SD card**
- Create partitions with **GParted** (or CLI - `fdisk` + `fatlabel` + `e2label`)

| Type    | No. | Label* | Format | Size       |
|---------|-----|--------|--------|------------|
| primary | #1  | BOOT   | fat32  | 100MB      |
| primary | #2  | ROOT   | ext4   | (the rest) |

\* **Label** - Important

```sh
# install bsdtar and nmap
apt install bsdtar namp

# get partitions and verify
ROOT=$( df | grep ROOT | awk '{print $NF}' )
BOOT=$( df | grep BOOT | awk '{print $NF}' )
df | grep 'ROOT\|BOOT'
echo ROOT = $ROOT
echo BOOT = $BOOT

# expand to sd card
bsdtar xpvf $file -C $ROOT
cp -rv --no-preserve=mode,ownership $ROOT/boot/* $BOOT
rm -r $ROOT/boot/*
```

**Boot**
- Remove all USB drives
- Insert the SD card
- Connect wired LAN
- Power on / connect RPi power

**Connect PC to RPi**
```sh
# get RPi IP address and verify
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap=$( nmap -sP ${routerip%.*}.* | grep -B2 Raspberry )
rpiip=$( echo "$nmap" | head -1 | awk '{print $NF}' )
echo List:
echo "$nmap"
echo RPi IP = $rpiip

# if there's more than 1 RPi, set rpiip manually
# rpiip=<ip>

# connect
ssh alarm@$rpiip  # password: alarm
```

**Packages**
```sh
# switch user to root
su  # password: root

# change directory
cd

# initialize pgp key
pacman-key --init
pacman-key --populate archlinuxarm

# if errors occured, temporarily bypass key verifications
# sed -i '/^SigLevel/ s/^/#/; a\SigLevel    = TrustAll' /etc/pacman.conf

# full upgrade
pacman -Syu

# package list
packages='alsa-utils avahi chromium dnsmasq dosfstools ffmpeg gcc hostapd ifplugd mpd mpc nfs-utils parted php-fpm python python-pip samba shairport-sync sudo udevil wget xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit'
```

**Exclude optional packages** (Skip to install all)
```sh
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

# optional - remove python
packages=${packages/ python python-pip}
```

**Install packages**
```sh
# install packages
pacman -S $packages

# optional - install RPi.GPIO
pip install RPi.GPIO
```

**Web interface, custom packages and config files**
- RuneAudio Enhancement interface
- Custom packages
	- `nginx-mainline` - support pushstream
	- `kid3-cli` - not available as standard package
	- `matchbox-window-manager` - not available as standard package
	- `upmpdcli` - not available as standard package
	- `ply-image` (single binary file)
- Configuration files set to default
- `Runonce.sh` for initial boot setup
```sh
# download
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf master.zip --strip 1 --exclude=.* --exclude=*.md -C /
chmod -R 755 /srv/http /usr/local/bin
chown -R http:http /srv/http
```

**Exclude optional packages** (Skip to install all)
```sh
# optional - remove metadata tag editor
rm kid3-cli*

# optional - remove UPnP
rm upmpdcli*
```

**Install custom packages**
```sh
# install custom packages
pacman -U *.pkg.tar.xz
rm *.pkg.tar.xz
```

**Fixes**
```sh
# alsa - Process '/usr/bin/alsactl restore 0' failed
alsactl store
chmod -R 666 /var/lib/alsa

# lvm - Invalid value
sed -i '/event_timeout/ s/^/#/' /usr/lib/udev/rules.d/11-dm-lvm.rules

# mpd - file not found
touch /var/log/mpd.log
chown mpd:audio /var/log/mpd.log

# systemd-random-seed - Kernel entropy pool is not initialized
systemctl start systemd-random-seed

# upmpdcli - older symlink
ln -s /lib/libjsoncpp.so.{21,20}

# wireless-regdom - /usr/bin/set-wireless-regdom failed
sed -i '/WIRELESS_REGDOM="00"/ s/^#//' /etc/conf.d/wireless-regdom
```

**Configurations**
```sh
# bootsplash - set default image
ln -s /srv/http/assets/img/{NORMAL,start}.png

# cron - for addons updates
( crontab -l &> /dev/null; echo '00 01 * * * /srv/http/addonsupdate.sh &' ) | crontab -

# hostname - set default
name=RuneAudio
namecl=runeaudio
echo $namecl > /etc/hostname
sed -i "s/^\(ssid=\).*/\1$name/" /etc/hostapd/hostapd.conf
sed -i 's/\(zeroconf_name           "\).*/\1$name"/' /etc/mpd.conf
sed -i "s/\(netbios name = \).*/\1$name/" /etc/samba/smb.conf
sed -i "s/^\(friendlyname = \).*/\1$name/" /etc/upmpdcli.conf
sed -i "s/\(.*\[\).*\(\] \[.*\)/\1$namelc\2/" /etc/avahi/services/runeaudio.service
sed -i "s/\(.*localdomain \).*/\1$namelc.local $namelc/" /etc/hosts

# login prompt - remove
systemctl disable getty@tty1

# mpd - music directories
mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# motd - remove default
rm /etc/motd

# ntp - set default
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf

# password - set default
passwd  # new password: rune

# ssh - permit root
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
```

**Startup services**
```sh
systemctl daemon-reload
systemctl enable avahi-daemon bootsplash devmon@mpd nginx php-fpm startup
```

**Finish**
```sh
# shutdown
shutdown -h now
```
- Power off / disconnect RPi power

**Create image file**
- Insert the micro SD card in PC
- Resize `ROOT` partition to smallest size possible with **GParted**.
- Create image file
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
dd if=$dev of=RuneAudio+Re2.img count=$(( end + 1 ))
```
OR on Windows (much faster):
- [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/) > Read only allocated partitions

**Start RuneAudio+R**
- Insert the micro SD card
- Plug in a USB drive
	- At least one is required. (1GB+)
	- Must be formatted to **`ext4`**
	- This can be the same drive that stores music files.
- Power on
