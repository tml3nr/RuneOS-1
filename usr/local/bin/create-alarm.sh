#!/bin/bash

[[ ! -e /usr/bin/bsdtar ]] && apt install -y bsdtar
[[ ! -e /usr/bin/nmap ]] && apt install -y nmap
[[ ! -e /usr/bin/pv ]] && apt install -y pv

trap 'rm -f ArchLinuxARM*' EXIT

cols=$( tput cols )
hr() { printf "\e[36m%*s\e[m\n" $cols | tr ' ' -; }
verifypath() {
	mountpoint=$( df | grep $1 | awk '{print $NF}' )
	if [[ -n $mountpoint ]]; then
		echo -e "\n$( df -h | grep $mountpoint )"
		echo -e "$1: \e[36m$mountpoint\e[m\n"
	else
		echo -e "\n\e[m36$1\e[m not mounted or incorrect label." && exit
	fi
	read -rn 1 -p "Confirm and continue? [y/N]: " ans; echo
	[[ $ans != y && $ans != Y ]] && exit
	[[ -n $( ls $mountpoint | grep -v 'lost+found\|System Volume Information' ) ]] && echo $mountpoint not empty. && exit
}
selectMode() {
	echo -e "\nRun ROOT partition on:"
	echo -e '  \e[36m1\e[m Micro SD card'
	echo -e '  \e[36m2\e[m USB drive'
	read -rn 1 -p "Select [1/2]: " mode; echo
	if [[ -z $mode || $mode -gt 5 ]]; then
		echo -e "\nSelect 1 or 2\n" && selectMode
	else
		[[ $mode == 1 ]] && dev='Micro SD card' || dev='USB drive'
		echo -e "\nRun ROOT on \e[36m$dev\e[m\n"
		read -rn 1 -p "Confirm and continue? [y/N]: " ans; echo
		[[ $ans != y && $ans != Y ]] && selectMode
	fi
}
selectSecurity() {
	echo Security:
	echo -e '  \e[36m1\e[m WPA'
	echo -e '  \e[36m2\e[m WEP'
	echo -e '  \e[36m3\e[m None'
	read -rn 1 -p 'Select [1-3]: ' ans
	if [[ -z $ans || $ans -gt 3 ]]; then
		echo -e "\nSelect 1, 2 or 3\n" && selectSecurity
	else
		if [[ $ans == 1 ]]; then
			wpa=wpa
		elif [[ $ans == 2 ]]; then
			wpa=wep
		else
			wpa=
		fi
	fi
}
setCredential() {
	read -p 'SSID: ' ssid
	read -p 'Password: ' password
	selectSecurity
	echo -e "\n\nSSID: \e[36m$ssid\e[m\nPassword: \e[36m$password\e[m\nSecurity: \e[36m${wpa^^}\e[m\n"
	read -rn1 -p "Confirm and continue? [y/N]: " ans; echo; echo
	[[ $ans != Y && $ans != y ]] && setCredential
}
selectRPi() {
	echo -e "\nRaspberry Pi:"
	echo -e '  \e[36m0\e[m RPi Zero'
	echo -e '  \e[36m1\e[m RPi 1'
	echo -e '  \e[36m2\e[m RPi 2'
	echo -e '  \e[36m3\e[m RPi 3'
	echo -e '  \e[36m4\e[m RPi 4'
	echo -e '  \e[36m5\e[m RPi 3+'
	read -rn 1 -p "Select [0-5]: " rpi; echo
	if [[ -z $rpi || $rpi -gt 5 ]]; then
		echo -e "\nSelect 0, 1, 2, 3, 4 or 5\n" && selectRPi
	else
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
	fi
	echo -e "\nRaspberry Pi \e[36m$rpi\e[m\n"
	read -rn 1 -p "Confirm and continue? [y/N]: " ans; echo
	[[ $ans != y && $ans != Y ]] && selectRPi
}

# -----------------------------------------------------------------------
hr
echo -e "\n\e[36mCreate Arch Linux Arm ...\e[m\n"
hr

verifypath BOOT
BOOT=$mountpoint

verifypath ROOT
ROOT=$mountpoint

selectMode

selectRPi

read -ren 1 -p $'\nAuto-connect Wi-Fi on boot? [y/N]: ' ans; echo
[[ $ans == y || $ans == Y ]] && setCredential

# -----------------------------------------------------------------------
echo -e "\n\e[36mDownloading ...\e[m\n"

wget -qN --show-progress http://os.archlinuxarm.org/os/$file
wget -qN --show-progress http://os.archlinuxarm.org/os/$file.md5

# verify
echo -e "\nVerify downloaded file ...\n"
! md5sum -c $file.md5 && echo -e "\nDownload incomplete!\n" && exit

#---------------------------------------------------------------------------------
echo -e "\n\e[36mExpand to BOOT partition ...\e[m\n"

pv $file | bsdtar -C $BOOT --totals --strip-components=2 --no-same-permissions --no-same-owner -xf - boot

#---------------------------------------------------------------------------------
echo -e "\n\e[36mExpand to ROOT partition ...\e[m\n"

mkdir $ROOT/boot
pv $file | bsdtar -C $ROOT --totals --exclude='boot' -xpf -

# complete write from cache to disk before continue
echo -e "\nIt takes some time to complete writing SD card or thumb drive ..."
sync

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

echo -e "\n\e[36mArch Linux Arm for Raspberry Pi $rpi created successfully.\e[m\n"
hr

read -ren 1 -p $'\nRaspberry Pi has pre-assigned IP address? [y/N]: ' ans; echo
if [[ $ans != y && $ans != Y ]]; then
	echo -e "Scan IP address of existing hosts ...\n"
	routerip=$( ip route get 1 | cut -d' ' -f3 )
	nmap -sP ${routerip%.*}.*
fi

umount -l $BOOT && umount -l $ROOT && echo -e "\n$ROOT and $BOOT unmounted."

echo -e "\nMove micro SD card (and optional USB drive) to RPi."
echo -e "Power on and wait 30 seconds for boot process.\n"
read -resn 1 -p $'Press any key to continue\n'; echo

if [[ $ans != y && $ans != Y ]]; then
	echo -e "\nRescan IP address ...\n"
	nmap -sP ${routerip%.*}.*
	echo -e "\nFind IP address of Raspberry Pi."
	echo -e "(Compare with previous scan and if necessary. Raspberry Pi 4 may listed as unknown.)\n"
fi

read -r -p "Raspberry Pi IP: " rpiip; echo
echo -e "Raspberry Pi IP: \e[36m$rpiip\e[m\n"
read -ren 1 -p 'Confirm and continue? [y/N]: ' ans; echo
[[ $ans != y && $ans != Y ]] && exit

# remove existing key if any and connect
ssh-keygen -R $rpiip &> /dev/null
ssh alarm@$rpiip
