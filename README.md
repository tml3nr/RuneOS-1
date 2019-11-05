RuneOS
---
- For all Raspberry Pi: Zero, 1, 2, 3 and 4 (3+: not yet tested but should work)
- Build RuneAudio+Re from [**Arch Linux Arm**](https://archlinuxarm.org/about/downloads) latest releases.
- With options to exclude features, it can be as light as possible in terms of build time and disk space.

**Procedure**
- Prepare partitions
- Create Arch Linux Arm
	- Verify partitions
	- Optional - pre-configure Wi-Fi connection (headless mode)
	- Download
	- Write `ROOT` and `BOOT` partitions
- Connect PC to Raspberry Pi
	- Start Arch Linux Arm
	- Get IP address
	- Connect
- Create RuneAudio+Re
	- Verify partitions
	- Optional - select features
	- Upgrade kernel and default packages
	- Install packages and web interface
	- Configure
	- Set default settings

**Need**
- Linux PC (or Linux in VirtualBox on Windows with network set as `Bridge Adapter`)
	- GParted and Files app (normally already installed)
	- Basic skill of terminal command line
- Raspberry Pi
- Network connection to Raspberry Pi 
	- Wired LAN
	- Optional: Wi-Fi if necessary
- Micro SD card: 4GB+ - `BOOT` + `ROOT` partitions
- Optional: Micro SD card + USB drive (run RuneAudio+R from USB drive)
	- Micro SD card: 100MB+ - `BOOT` partition only
	- USB drive: 4GB+ - `ROOT` partition (or existing USB hard drive with data)
	- For hard drives or faster-than-SD-card thumb drives
---

### Prepare partitions

**Micro SD card only**
- Insert micro SD card
- Delete all partitions (make sure it's the micro SD card)
- Create partitions with **GParted** app

| No. | Size        | Type    | Format | Label |
|-----|-------------|---------|--------|-------|
| #1  | 100MiB      | primary | fat32  | BOOT  |
| #2  | (the rest)  | primary | ext4   | ROOT  |
	
**Optional: Micro SD card + USB drive**
- Micro SD card
	- Delete all partitions (Caution: make sure it's the SD card)
	- Format: `fat32`
	- Label: `BOOT`
- USB drive
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

### Create Arch Linux Arm

- Open **Files** app - click `BOOT` and `ROOT` to mount
- Hover mouse over `BOOT` and `ROOT` and note the paths
- Download and write `BOOT` and `ROOT`
```sh
# switch user to root
su

# get script
wget -qN --show-progress https://github.com/rern/RuneOS/raw/master/usr/local/bin/create-alarm.sh
chmod +x create-alarm.sh
./create-alarm.sh
# if download is too slow, ctrl+c and run ./create-alarm.sh again
# note: RPi 3 shows filename as ArchLinuxARM-rpi-2-latest.tar.gz
```
- **Finished** - If unattended, scroll up to look for any errors.

### Connect PC to Raspberry Pi
- At `Are you sure you want to continue connecting (yes/no)?`, confirm `yes` and login with password: `alarm`

**(skip if connected successfully) If connection failed or RPi not show up in scan**
- Power off RPi
- If not yet on wired LAN, connect it.
- Power on and scan again
```sh
# scan ip address
routerip=$( ip route get 1 | cut -d' ' -f3 )
nmap -sP ${routerip%.*}.*
# If still not found, start over again

# connect
read -r -p "Raspberry Pi IP: " rpiip; echo
echo -e "\nRaspberry Pi IP: $rpiip\n"
read -ren 1 -p 'Confirm and continue? [y/N]: ' ans; echo
[[ $ans != y && $ans != Y ]] && exit

# remove existing key if any and connect
ssh-keygen -R $rpiip &> /dev/null
ssh alarm@$rpiip
```

### Create RuneAudio+Re

- For default setup: select `Install all`
- Feature options:
	- Avahi - Connect by: `runeaudio.local`
	- Bluez - Bluetooth support
	- Chromium - Browser on RPi (Not available for RPi Zero and 1 - too much for CPU)
	- FFmpeg - [Extended decoders](https://github.com/rern/RuneOS/blob/master/ffmpeg.md)
	- hostapd - RPi access point
	- Kid3 - Metadata tag editor
	- Python - Programming language
	- Samba - File sharing
	- Shairport-sync - AirPlay
	- upmpdcli - UPnP
```sh
# switch user to root
su
# password: root

# build script
create-rune.sh
# if download is too slow or errors occured, ctrl+c and run create-rune.sh again
```

- **Finish** - If unattended, scroll up to look for any errors.

---

**Optional**
- [Setup Wi-Fi auto-connect](https://github.com/rern/RuneAudio/tree/master/wifi_setup) (if not set during build)
- [Create image file](https://github.com/rern/RuneOS/blob/master/imagefile.md)
