RuneOS
---
- For all Raspberry Pi: 0, 1, 2, 3 and 4 (3A+ and 3B+: not yet tested but should work)
- Build RuneAudio+R from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Download and write to `ROOT` and `BOOT` partitions
- Start Arch Linux Arm
- (Optional) Pre-configure Wi-Fi connection for headless(no monitor) system
- Upgrade kernel and default packages to latest versions
- Install packages with options to exclude features
- Configure settings

**Need**
- Linux PC (or Linux in VirtualBox on Windows with network set as `Bridge Adapter`)
	- GParted and Files app (normally already installed)
	- Basic skill of terminal command line
- Raspberry Pi
- Network connection
	- Wired LAN (more stable)
	- Wi-Fi connection (only if necessary)
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
# if download is too slow,ctrl+c > ./write-alarm.sh again

rm write-alarm.sh
```

**Start Arch Linux Arm**
- Move micro SD card (and USB drive if in USB drive mode) to RPi
- Plug in wired LAN (RPi without wired LAN or Wi-Fi - plug in USB Wi-Fi)
- Remove all other USB devices if any
- Power on
- Wait 30 seconds

▼ skip if already known IP ▼ **Get IP address of RPi**
- On Linux PC
```sh
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap -sP ${routerip%.*}.*
```
- If RPi not show up in result:
	- RPi 4 may listed as unknown
	- Restart router and scan with `nmap -sP ${routerip%.*}.*` again
	- Still not found, plugin wired LAN and scan again
	- Still not found, connect a monitor/tv and a keyboard
```sh
# login user: alarm, password: alarm

# connect wifi
su  # password: root
wifi-menu
```
- Still not found, start over again

**Connect PC to RPi**
- On Linux PC
```sh
# set ip
read -r -p "RPi IP: " rpiip; echo

# remove existing key if any
ssh-keygen -R $rpiip 2> /dev/null

# connect
ssh alarm@$rpiip  # confirm: yes > password: alarm
```

**Build RuneAudio+Re**
- Select - Install all for default setup
- Chromium - Browser on RPi - Not available for RPi 0 and 1 (too much for CPU)
- FFmpeg - Select install for extended decoder: 16sv 3g2 3gp 4xm 8svx aa3 aac ac3 adx afc aif aifc aiff al alaw amr anim apc ape asf atrac au aud avi avm2 avs bap bfi c93 cak cin cmv cpk daud dct divx dts dv dvd dxa eac3 film flac flc fli fll flx flv g726 gsm gxf iss m1v m2v m2t m2ts m4a m4b m4v mad mj2 mjpeg mjpg mka mkv mlp mm mmf mov mp+ mp1 mp2 mp3 mp4 mpc mpeg mpg mpga mpp mpu mve mvi mxf nc nsv nut nuv oga ogm ogv ogx oma ogg omg opus psp pva qcp qt r3d ra ram rl2 rm rmvb roq rpl rvc shn smk snd sol son spx str swf tak tgi tgq tgv thp ts tsp tta xa xvid uv uv2 vb vid vob voc vp6 vmd wav webm wma wmv wsaud wsvga wv wve
```sh
# switch user to root
su # password: root

# change directory to root
cd

# build script
write-rune.sh
# if download is too slow or errors occured, ctrl+c > write-rune.sh again
```

▼ skip if NOT install UPnP ▼ upmpdcli - generate RSA private key
```sh
if [[ -e /usr/bin/upmpdcli ]]; then
    mpd --no-config 2> /dev/null
    upmpdcli -c /etc/upmpdcli.conf
fi
# Ctrl+C at 'writing RSA key'
```

**Finish**
```sh
# reboot
shutdown -r now
```
---

**Optional**
- [Setup Wi-Fi auto-connect](https://github.com/rern/RuneAudio/tree/master/wifi_setup) (if not set during build)
- [Create image file](https://github.com/rern/RuneOS/blob/master/imagefile.md)
