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
trap 'rm -f ArchLinuxARM*' EXIT

title='Create Arch Linux Arm'
dialog --colors \
    --infobox "\n             \Z1$title\Z0\n" 5 50
sleep 3

BOOT=$( df | grep BOOT | awk '{print $NF}' )
ROOT=$( df | grep ROOT | awk '{print $NF}' )

# get build data --------------------------------------------------------------
dialog --backtitle "$title" --colors \
	--yesno "\n\Z1Confirm path:\Z0\n\n\
BOOT: \Z1$BOOT\Z0\n\
ROOT: \Z1$ROOT\Z0\n\n" 0 0
[[ $? == 1 || $? == 255 ]] && clear && exit
	
rpi=$( dialog --backtitle "$title" --colors \
	--output-fd 1 \
	--radiolist '\n\Z1Target:\Z0' 0 0 6 \
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

mode=$( dialog --backtitle "$title" --colors\
	--output-fd 1 \
	--radiolist "\n\Z1Run on:\Z0" 0 0 2 \
        1 'Micro SD card' on \
        2 'USB drive' off )
[[ $? == 255 ]] && clear && exit
[[ $mode == 1 ]] && dev='Micro SD card' || dev='USB drive'

dialog --backtitle "$title" --colors\
	--yesno '\n\Z1Connect Wi-Fi on boot?\Z0\n\n' 0 0
ans=$?
[[ $ans == 255 ]] && clear && exit

if [[ $ans == 0 ]]; then
	ssid=$( dialog --backtitle "$title" \
		--output-fd 1 \
		--inputbox 'Wi-Fi - SSID:' 0 0 )
    [[ $? == 255 ]] && clear && exit

	password=$( dialog --backtitle "$title" \
		--output-fd 1 \
		--inputbox 'Wi-Fi - Password:' 0 0 )
    [[ $? == 255 ]] && clear && exit
		
	wpa=$( dialog --backtitle "$title" \
		--output-fd 1 \
		--radiolist 'Wi-Fi -Security:' 0 0 3 \
			1 'WPA' on \
			2 'WEP' off \
			2 'None' off )
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
 Security : \Z1${wpa^^}\Z0\n\n"
fi

dialog --backtitle "$title" --colors \
	--yesno "\n\Z1Confirm data:\Z0\n\n\
BOOT path : \Z1$BOOT\Z0\n\
ROOT path : \Z1$ROOT\Z0\n\
Target    : \Z1Raspberry Pi $rpi\Z0\n\
Run on    : \Z1$dev\Z0\n\n\
$wifi" 0 0
[[ $? == 1 || $? == 255 ]] && clear && exit

#-------------------------------------------------------------------------------
# download
wget http://os.archlinuxarm.org/os/$file 2>&1 | \
    stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
    dialog --gauge "Download Arch Linux Arm ..." 0 50
wget http://os.archlinuxarm.org/os/$file.md5 2>&1 | \
    stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
    dialog --gauge "Download checksum ..." 0 50

# expand
pv -n $file | bsdtar -C $BOOT --totals --strip-components=2 --no-same-permissions --no-same-owner -xf - boot 2>&1 | \
    dialog --gauge "Expand to BOOT ..." 0 50
pv -n $file | bsdtar -C $ROOT --totals --exclude='boot' -xpf - 2>&1 | \
    dialog --gauge "Expand to ROOT ...\n" 0 50

dialog --colors \
    --infobox "\n\Z1Be patient.\Z0\nIt may takes 10+ minutes \nto complete writing SD card or thumb drive." 7 50
sync

# USB drive mode
if [[ $mode == 2 ]]; then
	dev=$( df | grep ROOT | awk '{print $1}' )
	uuid=$( /sbin/blkid | grep $dev | cut -d' ' -f3 | tr -d '\"' )
	sed -i "s|/dev/mmcblk0p2|$uuid|" $BOOT/cmdline.txt
	echo "$uuid  /  ext4  defaults  0  0" >> $ROOT/etc/fstab
fi

# RPi 0 - fix: kernel panic
[[ $rpi == Zero ]] && echo -e 'force_turbo=1\nover_voltage=2' >> $BOOT/config.txt

# wifi
if [[ $ssid ]]; then
	echo -e "\n\e[36mSetup Wi-Fi ...\e[m\n"
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
    --infobox "\n       Arch Linux Arm for \Z1Raspberry Pi $rpi\Z0\n\
              created successfully.\n" 6 50
sleep 3

dialog --msgbox "\nMove micro SD card (and optional USB drive) to RPi.\n
Power on and wait 30 seconds for boot then press ok to continue" 7 100

#-------------------------------------------------------------------------------
# scan ip
dialog --backtitle "Connect to Raspberry Pi" --colors\
	--yesno '\n\Z1Scan for IP address of Raspberry Pi?\Z0\n\n' 0 0
ans=$?
[[ $ans == 255 ]] && clear && exit

if [[ $ans == 1 ]]; then
    dialog --infobox "\nScan IP address ..." 5 50
    routerip=$( ip route get 1 | cut -d' ' -f3 )
    nmap=$( nmap -sP ${routerip%.*}.* | grep -v 'Starting\|Host is up\|Nmap done' | head -n -1 | sed 's/$/\\n/; s/Nmap.*for/\\nIP  :/; s/Address//' | tr -d '\n' )
    dialog --colors --msgbox "\n\Z1Find IP address of Raspberry Pi:\Z0\n
(Raspberri Pi 4 may listed as Unknown)\n
$nmap" 50 100
fi

# connect RPi
rpiip=$( dialog --backtitle "Connect to Raspberry Pi" \
    --output-fd 1 \
    --inputbox 'Raspberry Pi IP:' 0 0 )
[[ $? == 255 ]] && clear && exit

clear

ssh-keygen -R $rpiip &> /dev/null
ssh alarm@$rpiip
