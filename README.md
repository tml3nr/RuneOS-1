RuneOS
---
- For all Raspberry Pi: 0, 1, 2, 3 and 4 (3A+ and 3B+: not yet tested but should work)
- Build RuneAudio+Re from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Download and write to `ROOT` and `BOOT` partitions
- (Optional) Pre-configure Wi-Fi connection for headless system (no monitor)
- Start Arch Linux Arm
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
- Normal SD mode (normal)
	- Micro SD card - 4GB+ - `BOOT` + `ROOT` partitions
- USB drive mode  (run RuneAudio+R from USB drive - hard drive or fast thumb drive)
	- Micro SD card - 100MB+ - `BOOT` partition only
	- USB drive - 4GB+ - `ROOT` partition (or existing USB hard drive with data)
---

### Build

- On Linux PC
	- Command lines - gray code blocks
	- Copy-paste unless corrections needed
	- Comments - Lines with leading `#` can be skipped.

**Prepare partitions**
- **SD card mode**
	- Insert micro SD card
	- Delete all partitions (make sure it's the micro SD card)
	- Create partitions with **GParted** app

| No. | Size        | Type    | Format | Label |
|-----|-------------|---------|--------|-------|
| #1  | 100MiB      | primary | fat32  | BOOT  |
| #2  | (the rest)  | primary | ext4   | ROOT  |
	
- **USB drive mode**
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
- Open **Files** app - click `BOOT` and `ROOT` to mount
- Hover mouse over `BOOT` and `ROOT` and note the paths

**Download and write `BOOT` and `ROOT`**
```sh
# switch user to root
su -

# write script
wget -qN --show-progress https://github.com/rern/RuneOS/raw/master/usr/local/bin/write-alarm.sh
chmod +x write-alarm.sh
./write-alarm.sh
# if download is too slow,ctrl+c > ./write-alarm.sh again

# remove downloaded file
rm write-alarm.sh

# scan IP list for reference
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap -sP ${routerip%.*}.*
```

**Start Arch Linux Arm**
- Move micro SD card (and USB drive if in USB drive mode) to RPi
- Plug in wired LAN (RPi without wired LAN or Wi-Fi - plug in USB Wi-Fi)
- Remove all other USB devices if any
- Power on
- Wait 30 seconds

**Get IP address of RPi** - On Linux PC:
```sh
# scan IP list again and compare to find new one => RPi
nmap -sP ${routerip%.*}.*

# If RPi not show up in result:
#	- RPi 4 may listed as unknown
#	- Restart router and scan again
#	- Still not found, plugin wired LAN and scan again
#	- Still not found, start over again
```

**Connect PC to RPi**
- On Linux PC
```sh
# set ip
read -r -p "Raspberry Pi IP: " rpiip; echo

# remove existing key if any
ssh-keygen -R $rpiip 2> /dev/null

# connect
ssh alarm@$rpiip  # confirm: yes > password: alarm
```

**Build RuneAudio+Re**
- For default setup - select - Install all
- Feature options:
	- Avahi - Connect by: runeaudio.local
	- Bluez - Bluetooth supports
	- Chromium - Browser on RPi - Not available for RPi 0 and 1 (too much for CPU)
	- FFmpeg - Select install for [extended decoders](https://github.com/rern/RuneOS/blob/master/ffmpeg.md)
	- hostapd - RPi access point
	- Kid3 - Metadata tag editor
	- Python - programming language
	- Samba - File sharing
	- Shairport-sync - AirPlay
	- upmpdcli - UPnP
```sh
# switch user to root
su -  # password: root

# build script
write-rune.sh
# if download is too slow or errors occured, ctrl+c > write-rune.sh again

# ▼ skip if NOT install UPnP ▼ fix - init RSA key
mpd --no-config &> /dev/null
upmpdcli
# ctrl+c when reach 'writing RSA key'
killall mpd upmpdcli
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
