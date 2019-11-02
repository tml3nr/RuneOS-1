RuneOS
---
- For all Raspberry Pi: Zero, 1, 2, 3 and 4 (3+: not yet tested but should work)
- Build RuneAudio+Re from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) latest releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Create Arch Linux Arm system
	- Prepare partitions
	- Download
	- Write `ROOT` and `BOOT` partitions
	- Optional - Pre-configure Wi-Fi connection
	- Start Arch Linux Arm
	- Connect PC to RPi
- Create RuneAudio+Re system
	- Upgrade kernel and default packages
	- Install packages and web interface
	- Configure
	- Set default settings

**Need**
- Linux PC (or Linux in VirtualBox on Windows with network set as `Bridge Adapter`)
	- GParted and Files app (normally already installed)
	- Basic skill of terminal command line
- Raspberry Pi
- Network connection - Wired LAN (or Wi-Fi if necessary)
- Micro SD card - 4GB+ - `BOOT` + `ROOT` partitions
- Optional: Micro SD card + USB drive (run RuneAudio+R from USB drive)
	- Micro SD card - 100MB+ - `BOOT` partition only
	- USB drive - 4GB+ - `ROOT` partition (or existing USB hard drive with data)
	- For hard drives or faster-than-SD-card thumb drives
---

### Create Arch Linux Arm system

**Prepare partitions**
- **Micro SD card only**
	- Insert micro SD card
	- Delete all partitions (make sure it's the micro SD card)
	- Create partitions with **GParted** app

| No. | Size        | Type    | Format | Label |
|-----|-------------|---------|--------|-------|
| #1  | 100MiB      | primary | fat32  | BOOT  |
| #2  | (the rest)  | primary | ext4   | ROOT  |
	
- **Optional: Micro SD card + USB drive**
	- Insert Micro SD card
		- Delete all partitions (Caution: make sure it's the SD card)
		- Format: `fat32`
		- Label: `BOOT`
	- Plug in USB drive
		- Blank drive:
			- Delete all partitions (Caution: make sure it's the USB drive)
			- Format: `ext4`
			- Label: `ROOT`
		- Drive with existing data:
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
wget -qN --show-progress https://github.com/rern/RuneOS/raw/master/usr/local/bin/create-alarm.sh
chmod +x create-alarm.sh
./create-alarm.sh
# if download is too slow, ctrl+c and ./create-alarm.sh again

# remove downloaded file
rm write-alarm.sh

# scan IP list for reference
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap -sP ${routerip%.*}.*
```

**Start Arch Linux Arm**
- Move micro SD card (and optional USB drive) to RPi
- Power on
- Wait 30 seconds

**Connect PC to RPi**
```sh
# scan IP list again and compare to find new one => RPi
nmap -sP ${routerip%.*}.*

# If RPi not show up in result:
#  - RPi 4 may listed as unknown
#  - If not use wired LAN:
#     - Connect with wired LAN
#     - Restart RPi
#     - Scan again
#  - If still not found, start over again

# set ip
read -r -p "Raspberry Pi IP: " rpiip; echo

# remove existing key if any
ssh-keygen -R $rpiip 2> /dev/null

# connect
ssh alarm@$rpiip  # confirm: yes > password: alarm
```

### Create RuneAudio+Re system

- For default setup: select `Install all`
- Feature options:
	- Avahi - Connect by: `runeaudio.local`
	- Bluez - Bluetooth support
	- Chromium - Browser on RPi (Not available for RPi Zero and 1 - too much for CPU)
	- FFmpeg - [Extended decoders](https://github.com/rern/RuneOS/blob/master/ffmpeg.md)
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
create-rune.sh
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
