#!/bin/bash

# required packages
if [[ -e /usr/bin/pacman ]]; then
	[[ ! -e /usr/bin/bsdtar ]] && packages+='bsdtar '
	[[ ! -e /usr/bin/dialog ]] && packages+='dialog '
	[[ ! -e /usr/bin/nmap ]] && packages+='nmap '
	[[ ! -e /usr/bin/pv ]] && packages+='pv '
	[[ -n $packages ]] && pacman -S --noconfirm --needed $packages
else
	[[ ! -e /usr/bin/bsdtar ]] && packages+='bsdtar '
	[[ ! -e /usr/bin/dialog ]] && packages+='dialog '
	[[ ! -e /usr/bin/nmap ]] && packages+='nmap '
	[[ ! -e /usr/bin/pv ]] && packages+='pv '
	[[ -n $packages ]] && apt install -y $packages
fi

# remove on exit
trap 'rm -f ArchLinuxARM*; clear; exit' INT
trap 'rm -f ArchLinuxARM*; clear' EXIT

#----------------------------------------------------------------------------
infobox() {
	[[ -z $2 ]] && w=0 || w=$2
	[[ -z $3 ]] && h=0 || h=$3
	dialog --backtitle "$title" --colors --infobox "\n$1\n" $w $h
}
inputbox() {
	dialog --backtitle "$title" --colors --output-fd 1 --inputbox "\n$1" 0 0 $2
}
msgbox() {
	[[ -z $2 ]] && w=0 || w=$2
	[[ -z $3 ]] && h=0 || h=$3
	dialog --backtitle "$title" --colors --msgbox "\n$1\n\n" $w $h
}
yesno() {
	dialog --backtitle "$title" --colors --yesno "\n$1\n\n" 0 0
}

title='Create Arch Linux Arm'
infobox "
                \Z1Arch Linux Arm\Z0\n
                      for\n
                 Raspberry Pi
" 7 50
sleep 3

BOOT=$( df | grep 'BOOT$' | awk '{print $NF}' )
ROOT=$( df | grep 'ROOT$' | awk '{print $NF}' )

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
	msgbox "\Z1Warnings:\n\n$warnings\Z0"
	clear && exit
fi

# get build data
getData() {
	yesno "\Z1Confirm path:\Z0\n\n\
BOOT: \Z1$BOOT\Z0\n\
ROOT: \Z1$ROOT\Z0"
	[[ $? == 1 ]] && clear && exit

	rpi=$( dialog --backtitle "$title" --colors --output-fd 1 \
		--menu '\n\Z1Target:\Z0' 0 0 6 \
			0 'Raspberry Pi Zero' \
			1 'Raspberry Pi 1' \
			2 'Raspberry Pi 2' \
			3 'Raspberry Pi 3' \
			4 'Raspberry Pi 4' \
			5 'Raspberry Pi 3+' )
	
	case $rpi in
		0|1) file=ArchLinuxARM-rpi-latest.tar.gz ;;
		2|3) file=ArchLinuxARM-rpi-2-latest.tar.gz ;;
		4) file=ArchLinuxARM-rpi-4-latest.tar.gz ;;
		5) file=ArchLinuxARM-rpi-3-latest.tar.gz; rpi=3+ ;;
	esac
	[[ $rpi == 0 ]] && rpi=Zero
	
	yesno '\Z1Connect Wi-Fi on boot?\Z0'
	if [[ $? == 0 ]]; then
		ssid=$( inputbox '\Z1Wi-Fi\Z0 - SSID:' $ssid )

		password=$( inputbox '\Z1Wi-Fi\Z0 - Password:' $password )

		wpa=$( dialog --backtitle "$title" --colors --output-fd 1 \
			--menu '\n\Z1Wi-Fi -Security:\Z1' 0 0 3 \
				1 'WPA' \
				2 'WEP' \
				3 'None' )
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

	yesno "\Z1Confirm data:\Z0\n\n\
BOOT path : \Z1$BOOT\Z0\n\
ROOT path : \Z1$ROOT\Z0\n\
Target    : \Z1Raspberry Pi $rpi\Z0\n\
$wifi"
	[[ $? == 1 ]] && getData
}
getData

# download
( wget http://os.archlinuxarm.org/os/$file 2>&1 | \
    stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { \
        print "XXX\n"substr($0,63,3)
        print "\\n\\Z1Download Arch Linux Arm\\Z0\\n"
        print "Time left: "substr($0,74,5)"\nXXX" }' ) | \
    dialog --backtitle "$title" --colors --gauge "\nConnecting ..." 9 50

# checksum
wget -qN http://os.archlinuxarm.org/os/$file.md5
if ! md5sum -c $file.md5; then
    msgbox '\Z1Download incomplete!\Z0\n\n
Run \Z1./create-alarm.sh\Z0 again.\n\n'
    exit
fi

# expand
( pv -n $file | bsdtar -C $BOOT --strip-components=2 --no-same-permissions --no-same-owner -xf - boot ) 2>&1 | \
	dialog --backtitle "$title" --colors --gauge "\nExpand to \Z1BOOT\Z0 ..." 9 50
( pv -n $file | bsdtar -C $ROOT --exclude='boot' -xpf - ) 2>&1 | \
	dialog --backtitle "$title" --colors --gauge "\nExpand to \Z1ROOT\Z0 ..." 9 50

infobox "\Z1Be patient.\Z0\n\n
It may take 10+ minutes to complete writing\n
from cache to SD card or thumb drive." 8 50
sync

#----------------------------------------------------------------------------
# fstab and cmdline.txt
PATH=$PATH:/sbin  # Debian not include /sbin in PATH
partuuidBOOT=$( blkid | grep $( df | grep BOOT | awk '{print $1}' ) | awk '{print $NF}' | tr -d '"' )
partuuidROOT=$( blkid | grep $( df | grep ROOT | awk '{print $1}' ) | awk '{print $NF}' | tr -d '"' )
echo "$partuuidBOOT  /boot  vfat  defaults  0  0
$partuuidROOT  /      ext4  defaults  0  0" > $ROOT/etc/fstab
echo "root=$partuuidROOT rw rootwait selinux=0 plymouth.enable=0 smsc95xx.turbo_mode=N dwc_otg.lpm_enable=0 elevator=noop fsck.repair=yes console=tty1" > $BOOT/cmdline.txt

# config.txt
[[ $rpi != 4 ]] && config+='
force_turbo=1'

# RPi 0 - fix: kernel panic and hdmi audio
[[ $rpi == Zero ]] && config+='
over_voltage=2
hdmi_drive=2'

config+='
gpu_mem=32
initramfs initramfs-linux.img followkernel
max_usb_current=1

### onboard wifi, bluetooth and audio
#dtoverlay=disable-wifi
dtoverlay=disable-bt
dtparam=audio=on

### display
disable_splash=1
disable_overscan=1

### i2s
#dtparam=i2s=on'

echo "$config" > $BOOT/config.txt

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
chmod 744 $ROOT/usr/local/bin/create-rune.sh

msgbox "
        Arch Linux Arm for \Z1Raspberry Pi $rpi\Z0\n\
               created successfully.
" 8 58

rm $0

#----------------------------------------------------------------------------
umount -l $BOOT
umount -l $ROOT

[[ ${partuuidBOOT:0:-3} != ${partuuidROOT:0:-3} ]] && usb=' and USB drive'
msgbox "\Z1Finish.\Z0\n\n
BOOT and ROOT were unmounted.\n
Move micro SD card$usb to RPi.\n
Power on.\n
\Z1Wait 30 seconds\Z0 then press \Z1Enter\Z0 to continue." 12 55

#----------------------------------------------------------------------------
title='Connect to Raspberry Pi'
# scan ip
routerip=$( ip route get 1 | cut -d' ' -f3 )
subip=${routerip%.*}.
scanIP() {
	infobox "Scan IP address ..." 5 50
	nmap=$( nmap -sP $subip* | grep -v 'Starting\|Host is up\|Nmap done' | head -n -1 | tac | sed 's/$/\\n/; s/Nmap.*for/IP  :/; s/MAC Address/\\nMAC/' | tr -d '\n' )
	msgbox "\Z1Find IP address of Raspberry Pi:\Z0\n
(Raspberri Pi 4 may listed as Unknown)\n
\Z4[arrowdown] = scrolldown\Z0\n
$nmap" 50 100

	dialog --backtitle "$title" --colors \
		--ok-label Yes --extra-button --extra-label Rescan --cancel-label No \
		--yesno '\n\Z1Found IP address of Raspberry Pi?\Z0' 7 38
	ans=$?
	if [[ $ans == 3 ]]; then
		scanIP
	elif [[ $ans == 1 && -n $rescan ]]; then
		diadog --msgbox '  Try starting over again.' 0 0
		clear && exit
	fi
}
scanIP

if [[ $ans == 1 ]]; then
	yesno '\Z1Connect with Wi-Fi?\Z0'
	if [[ $? == 0 ]]; then
		rescan=1
		msgbox '
- Power off\n
- Connect wired LAN\n
- Power on\n
- Wait 30 seconds
- Press Enter to rescan'
		scanIP
	else
		msgbox '
- Power off\n
- Connect a monitor/TV\n
- Power on and observe errors\n
- Try starting over again'
		clear && exit
	fi
fi

# connect RPi
rpiip=$( inputbox '\Z1Raspberry Pi IP:\Z0' $subip )

clear

ssh-keygen -R $rpiip &> /dev/null
ssh alarm@$rpiip

[[ $? == 0 ]] && rm $0
