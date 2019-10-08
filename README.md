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
- list: http://os.archlinuxarm.org/os/
```sh
# get user
whoami

sudo su
user=<user> # from previous command

# download - RPi2,3
file=ArchLinuxARM-rpi-2-latest.tar.gz
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
pacman-key --init && pacman-key --populate archlinuxarm

# Or temporarily bypass key verifications
sed -i '/^SigLevel/ s/^/#/; a\SigLevel    = TrustAll' /etc/pacman.conf
```

### Install packages
```sh
# full upgrade
pacman -Syu

# packages
pacman -S alsa-utils avahi chromium cronie dnsmasq ffmpeg gcc hostapd ifplugd mpd mpc parted php-fpm python python-pip samba shairport-sync sudo udevil wget
#cifs-utils nfs-utils

# custom packages
file=kid3-cli-3.7.1-1-armv7h.pkg.tar.xz
wget https://github.com/rern/RuneAudio/raw/master/kid3-cli/$file
pacman -U $file
rm $file

file=nginx-mainline-pushstream-1.17.3-1-armv7h.pkg.tar.xz
wget https://github.com/rern/RuneAudio/raw/master/nginx/$file
pacman -U $file
rm $file
mkdir -p /var/lib/nginx/client-body # fix - no directory found

libupnpp=libupnpp-0.17.1-1-armv7h.pkg.tar.xz
upmpdcli=upmpdcli-1.4.2-2-armv7h.pkg.tar.xz
wget https://github.com/rern/RuneAudio/raw/master/upmpdcli/$libupnpp
wget https://github.com/rern/RuneAudio/raw/master/upmpdcli/$upmpdcli
pacman -U $libupnpp $upmpdcli
rm $libupnpp $upmpdcli
ln -s /lib/libjsoncpp.so.{21,20} # fix - older link
```

### Configurations
```sh
# set hostname
hostname runeaudio
echo runeaudio > /etc/hostname

mkdir -p /mnt/MPD/{USB,NAS}
chown -R mpd:audio /mnt/MPD

# copy config files
wget -q --show-progress https://github.com/rern/RuneOS/archive/master.zip
bsdtar xvf master.zip --strip 1 --exclude=.* --exclude=*.md -C /
chmod 755 /srv/http/* /srv/http/settings/* /usr/local/bin/*
chown -R http:http /srv/http
systemctl daemon-reload

systemctl enable avahi-daemon cronie nginx php-fpm startup udevil
```
