RuneAudio+R
---
Build RuneAudio+R from Arch Linux Arm source.

**Need**
- Linux PC
- Micro SD card - 4GB+

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
- Create partitions - GUI - GParted (or CLI - `fdisk` + `fatlabel` + `e2label`)

| Type    | No. | Label* | Format | Size     |
|---------|-----|--------|--------|----------|
| primary | #1  | BOOT   | fat32  | 100MB    |
| primary | #2  | ROOT   | ext4   | 3.5GB    |

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
- Power on / connect RPi power

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

# package list
packages='alsa-utils avahi chromium dnsmasq dosfstools ffmpeg gcc hostapd ifplugd mpd mpc nfs-utils parted php-fpm python python-pip samba shairport-sync sudo udevil wget xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit'

# remove optional - access point
packages=${packages/ dnsmasq}
packages=${packages/ hostapd}

# remove optional - airplay
packages=${packages/ shairport-sync}

# remove optional - browser on rpi
packages=${packages/ chromium}
packages=${packages/ xorg-server xf86-video-fbdev xf86-video-vesa xorg-xinit}

# remove optional - extended audio format:
#   16sv 3g2 3gp 4xm 8svx aa3 aac ac3 adx afc aif aifc aiff al alaw amr anim apc ape asf atrac au aud avi avm2 avs 
#   bap bfi c93 cak cin cmv cpk daud dct divx dts dv dvd dxa eac3 film flac flc fli fll flx flv g726 gsm gxf iss 
#   m1v m2v m2t m2ts m4a m4b m4v mad mj2 mjpeg mjpg mka mkv mlp mm mmf mov mp+ mp1 mp2 mp3 mp4 mpc mpeg mpg mpga mpp mpu mve mvi mxf 
#   nc nsv nut nuv oga ogm ogv ogx oma ogg omg opus psp pva qcp qt r3d ra ram rl2 rm rmvb roq rpl rvc shn smk snd sol son spx str swf 
#   tak tgi tgq tgv thp ts tsp tta xa xvid uv uv2 vb vid vob voc vp6 vmd wav webm wma wmv wsaud wsvga wv wve
packages=${packages/ ffmpeg}

# remove optional - file sharing
packages=${packages/ samba}

# remove optional - python (python3)
packages=${packages/ python python-pip}

# install packages
pacman -S $packages

# install optional - RPi.GPIO
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

# optional - metadata tag editor - exclude from install
rm kid3-cli*

# remove optional - UPnP
rm upmpdcli*

# install custom packages
pacman -U *.pkg.tar.xz
rm *.pkg.tar.xz
```

**Fixes**
```sh
# alsa - Process '/usr/bin/alsactl restore 0' failed
alsactl store
chmod -R 666 /var/lib/alsa

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
name=RuneAudio
namecl=runeaudio
echo $namecl > /etc/hostname
sed -i "s/^\(ssid=\).*/\1$name/" /etc/hostapd/hostapd.conf
sed -i 's/\(zeroconf_name           "\).*/\1$name"/' /etc/mpd.conf
sed -i "s/\(netbios name = \).*/\1$name/" /etc/samba/smb.conf
sed -i "s/^\(friendlyname = \).*/\1$name/" /etc/upmpdcli.conf
sed -i "s/\(.*\[\).*\(\] \[.*\)/\1$namelc\2/" /etc/avahi/services/runeaudio.service
sed -i "s/\(.*localdomain \).*/\1$namelc.local $namelc/" /etc/hosts

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
systemctl enable avahi-daemon bootsplash devmon@mpd nginx php-fpm startup
```

**Finish**
```sh
# shutdown
shutdown -h now
```
- Power off / disconnect RPi power

**Create image file**
- Windows
	- Win32 Disk Imager > Read only allocated partitions
- Linux
	- ?

**Start RuneAudio+R**
- Plug in a USB drive
	- At least one is required. (1GB+)
	- This can be the same drive that stores music files.
- Power on
