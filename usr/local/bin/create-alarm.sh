#!/bin/bash

# required packages
if [[ -e /usr/bin/pacman ]]; then
	[[ ! -e /usr/bin/bsdtar ]] && pacman -S --noconfirm --needed bsdtar
	[[ ! -e /usr/bin/dialog ]] && pacman -S --noconfirm --needed dialog
	[[ ! -e /usr/bin/nmap ]] && pacman -S --noconfirm --needed nmap
	[[ ! -e /usr/bin/pv ]] && pacman -S --noconfirm --needed pv
else
	[[ ! -e /usr/bin/bsdtar ]] && apt install -y bsdtar
	[[ ! -e /usr/bin/dialog ]] && apt install -y dialog
	[[ ! -e /usr/bin/nmap ]] && apt install -y nmap
	[[ ! -e /usr/bin/pv ]] && apt install -y pv
fi

# remove on exit
trap 'rm -f ArchLinuxARM*; clear' EXIT

#----------------------------------------------------------------------------
title='Create Arch Linux Arm'
dialog --colors \
	--infobox "\n
            \Z1$title\Z0\n
                      for\n
                 Raspberry Pi
" 7 50
sleep 3

BOOT=$( df | grep BOOT | awk '{print $NF}' )
ROOT=$( df | grep ROOT | awk '{print $NF}' )

# check mounts
[[ -z $BOOT ]] && warnings+='BOOT not mounted\n'
[[ -z $ROOT ]] && warnings+='ROOT not mounted\n'
# check duplicate names
[[ -n $BOOT && ${#[BOOT[@]} -gt 1 ]] && warnings+='BOOT has more than 1\n'
[[ -n $ROOT && ${#[ROOT[@]} -gt 1 ]] && warnings+='ROOT has more than 1\n'
# check empty to prevent wrong partitions
[[ -n $BOOT && -n $( ls $BOOT | grep -v 'System Volume Information' ) ]] && warnings+='BOOT not empty\n'
[[ -n $ROOT && -n $( ls $ROOT | grep -v 'lost+found' ) ]] && warnings+='ROOT not empty\n'
# partition warnings
if [[ -n $warnings ]]; then
	dialog --backtitle "$title" --colors \
		--msgbox "\n\Z1Warnings:\n\n$warnings\Z0\n" 0 0
	clear && exit
fi

# get build data
getData() {
	dialog --backtitle "$title" --colors \
		--yesno "\n\Z1Confirm path:\Z0\n\n\
	BOOT: \Z1$BOOT\Z0\n\
	ROOT: \Z1$ROOT\Z0\n\n" 0 0
	[[ $? == 1 || $? == 255 ]] && clear && exit

	rpi=$( dialog --backtitle "$title" --colors --output-fd 1 \
		--radiolist '\n\Z1Target:\Z0\n[space] = select' 0 0 6 \
			0 'Raspberry Pi Zero' off \
			1 'Raspberry Pi 1' off \
			2 'Raspberry Pi 2' off \
			3 'Raspberry Pi 3' on \
			4 'Raspberry Pi 4' off \
			5 'Raspberry Pi 3+' off )
	[[ $? == 255 ]] && clear && exit

	if [[ $rpi == 0 || $rpi == 1 ]]; then
		file=ArchLinuxARM-rpi-latest.tar.gz
		[[ $rpi == 0 ]] && rpi=Zero
	elif [[ $rpi == 2 || $rpi == 3 ]]; then
		file=ArchLinuxARM-rpi-2-latest.tar.gz
	elif [[ $rpi == 5 ]]; then
		file=ArchLinuxARM-rpi-3-latest.tar.gz
		rpi=3+
	elif [[ $rpi == 4 ]]; then
		file=ArchLinuxARM-rpi-4-latest.tar.gz
	fi

	dialog --backtitle "$title" --colors \
		--yesno '\n\Z1Connect Wi-Fi on boot?\Z0\n\n' 0 0
	ans=$?
	[[ $ans == 255 ]] && clear && exit

	if [[ $ans == 0 ]]; then
		ssid=$( dialog --backtitle "$title" --output-fd 1 \
			--inputbox 'Wi-Fi - SSID:' 0 0 )
		[[ $? == 255 ]] && clear && exit

		password=$( dialog --backtitle "$title" --output-fd 1 \
			--inputbox 'Wi-Fi - Password:' 0 0 )
		[[ $? == 255 ]] && clear && exit

		wpa=$( dialog --backtitle "$title" --output-fd 1 \
			--radiolist '\n\Z1Wi-Fi -Security:\Z0\n[space] = select' 0 0 3 \
				1 'WPA' on \
				2 'WEP' off \
				3 'None' off )
		[[ $? == 255 ]] && clear && exit

		if [[ $wpa == 1 ]]; then
			wpa=wpa
		elif [[ $wpa == 2 ]]; then
			wpa=wep
		else
			wpa=
		fi
		wifi="Wi-Fi settings\n\
	 SSID     : \Z1$ssid\Z0\n\
	 Password : \Z1$password\Z0\n\
	 Security : \Z1${wpa^^}\Z0\n"
	fi

	dialog --backtitle "$title" --colors \
		--yesno "\n\Z1Confirm data:\Z0\n\n\
	BOOT path : \Z1$BOOT\Z0\n\
	ROOT path : \Z1$ROOT\Z0\n\
	Target    : \Z1Raspberry Pi $rpi\Z0\n\
	$wifi\n" 0 0
	ans=$?
	if [[ $ans == 255 ]]; then
		clear && exit
	elif [[ $ans == 1 ]]; then
		getData
	fi
}
getData

# download
wget http://os.archlinuxarm.org/os/$file 2>&1 | \
	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
	dialog --backtitle "$title" --colors \
		--gauge "\n\Z1Download Arch Linux Arm ...\Z0\n[Ctrl+C] = cancel" 9 50

# checksum
wget -qN http://os.archlinuxarm.org/os/$file.md5
if ! md5sum -c $file.md5; then
    dialog --backtitle "$title" --colors \
        --msgbox '\n\Z1Download incomplete!\Z0\n' 0 0
    exit
fi

# expand
( pv -n $file | bsdtar -C $BOOT --strip-components=2 --no-same-permissions --no-same-owner -xf - boot ) 2>&1 | \
	dialog --backtitle "$title" \
		--gauge "Expand to BOOT ..." 0 50
( pv -n $file | bsdtar -C $ROOT --exclude='boot' -xpf - ) 2>&1 | \
	dialog --backtitle "$title" \
		--gauge "Expand to ROOT ...\n" 0 50

dialog --backtitle "$title" --colors \
	--infobox "\n\Z1Be patient.\Z0\n
It may takes 10+ minutes to complete writing\n
from cache to SD card or thumb drive." 7 50
sync

#----------------------------------------------------------------------------
partuuidBOOT=$( /sbin/blkid | grep $( df | grep BOOT | awk '{print $1}' ) | awk '{print $NF}' | tr -d '"' )
partuuidROOT=$( /sbin/blkid | grep $( df | grep ROOT | awk '{print $1}' ) | awk '{print $NF}' | tr -d '"' )
sed -i "s|/dev/mmcblk0p2|$partuuidROOT|" $BOOT/cmdline.txt
echo "$partuuidBOOT  /boot  vfat  defaults  0  0
$partuuidROOT  /  ext4  defaults  0  0" > $ROOT/etc/fstab

# RPi 0 - fix: kernel panic
[[ $rpi == Zero ]] && echo -e 'force_turbo=1\nover_voltage=2' >> $BOOT/config.txt

# wifi
if [[ $ssid ]]; then
	# profile
	profile="Interface=wlan0
Connection=wireless
IP=dhcp
ESSID=\"$ssid\""
	[[ -n $wpa ]] && profile+="
Security=$wpa
Key=$password
"
	echo "$profile" > "$ROOT/etc/netctl/$ssid"

	# enable startup
	pwd=$PWD
	dir=$ROOT/etc/systemd/system/sys-subsystem-net-devices-wlan0.device.wants
	mkdir -p $dir
	cd $dir
	ln -s ../../../../lib/systemd/system/netctl-auto@.service netctl-auto@wlan0.service
	cd "$pwd"

fi

# get create-rune.sh
wget -qN https://github.com/rern/RuneOS/raw/master/usr/local/bin/create-rune.sh -P $ROOT/usr/local/bin
chmod +x $ROOT/usr/local/bin/create-rune.sh
[[ $? == 0 ]] && rm $0

umount -l $BOOT
umount -l $ROOT

dialog --colors \
	--msgbox "\n       Arch Linux Arm for \Z1Raspberry Pi $rpi\Z0\n\
              created successfully.\n" 8 58

#----------------------------------------------------------------------------
[[ ${partuuidBOOT:0:-3} == ${partuuidROOT:0:-3} ]] && usb=' and USB drive'
dialog --backtitle "$title" --colors \
	--msgbox "\n\Z1Finish.\Z0\n\n
BOOT and ROOT were unmounted.\n
Move micro SD card$usb to RPi.\n
Power on.\n
\Z1Wait 30 seconds\Z0 for boot then press ok to continue." 12 55

title='Connect to Raspberry Pi'
# scan ip
dialog --backtitle "$title" --colors \
	--defaultno \
	--yesno '\n\Z1Scan for IP address of Raspberry Pi?\Z0\n\n' 0 0
ans=$?
[[ $ans == 255 ]] && clear && exit

if [[ $ans == 0 ]]; then
	dialog --backtitle "$title" \
		--infobox "\nScan IP address ..." 5 50
	routerip=$( ip route get 1 | cut -d' ' -f3 )
	nmap=$( nmap -sP ${routerip%.*}.* | grep -v 'Starting\|Host is up\|Nmap done' | head -n -1 | sed 's/$/\\n/; s/Nmap.*for/\\nIP  :/; s/Address//' | tr -d '\n' )
	dialog --backtitle "$title" --colors \
		--msgbox "\n\Z1Find IP address of Raspberry Pi:\Z0\n
(Raspberri Pi 4 may listed as Unknown)\n
$nmap" 50 100
fi

# connect RPi
rpiip=$( dialog --backtitle "$title" \
	--inputbox 'Raspberry Pi IP:' 0 0 )
[[ $? == 255 ]] && clear && exit

clear

ssh-keygen -R $rpiip &> /dev/null
ssh alarm@$rpiip
