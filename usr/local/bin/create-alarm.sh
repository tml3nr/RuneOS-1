#!/bin/bash

[[ ! -e /usr/bin/bsdtar ]] && apt install -y bsdtar
[[ ! -e /usr/bin/nmap ]] && apt install -y nmap

cols=$( tput cols )
hr() {
	printf %"$cols"s | tr ' ' -
}
verifypath() {
	mountpoint=$( df | grep $1 | awk '{print $NF}' )
	if [[ -n $mountpoint ]]; then
		echo -e "\n$( df -h | grep $mountpoint )"
		echo -e "$1: \e[36m$mountpoint\e[m\n"
	else
		echo -e "\n\e[m36$1\e[m not mounted or incorrect label. && exit
	fi
	read -rn 1 -p "Confirm and continue? [y/n]: " ans; echo
	[[ $ans != y && $ans != Y ]] && exit
	[[ -n $( ls $mountpoint | grep -v lost+found ) ]] && echo $mountpoint not empty. && exit
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
		read -rn 1 -p "Confirm and continue? [y/n]: " ans; echo
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
	echo
	read -p 'SSID: ' ssid
	read -p 'Password: ' password
	selectSecurity
	echo
	hr
	echo -e "\nSSID: \e[36m$ssid\e[m\nPassword: \e[36m$password\e[m\nSecurity: \e[36m${wpa^^}\e[m"
	hr
	read -rn1 -p "Confirm and continue? [y/n]: " ans; echo
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
	hr
	echo -e "Raspberry Pi \e[36m$rpi\e[m"
	hr
	read -rn 1 -p "Confirm and continue? [y/n]: " ans; echo
	[[ $ans != y && $ans != Y ]] && selectRPi
}

# -----------------------------------------------------------------------
hr
echo -e "\n\e[m36Arch Linux Arm system ...\e[m\n"
hr

verifypath BOOT

verifypath ROOT

selectMode

selectRPi

read -ren 1 -p $'Auto-connect \e[36mWi-Fi\e[m on boot? [y/n]: ' ans; echo
[[ $ans == y || $ans == Y ]] && setCredential

# -----------------------------------------------------------------------
echo -e "\n\e[36mDownloading ...\e[m"

wget -qN --show-progress http://os.archlinuxarm.org/os/$file
[[ $? != 0 ]] && echo -e "\nDownload failed." && exit

#---------------------------------------------------------------------------------
echo -e "\n\e[36mExpand to ROOT ...\e[m"

bsdtar xpvf $file -C $ROOT
rm $file

#---------------------------------------------------------------------------------
echo -e "\n\e[36mMove /boot to BOOT ...\e[m"

mv -v $ROOT/boot/* $BOOT 2> /dev/null

if [[ $mode == 2 ]]; then
	dev=$( df | grep ROOT | awk '{print $1}' )
	uuid=$( /sbin/blkid | grep $dev | cut -d' ' -f3 | tr -d '\"' )
	sed -i "s|/dev/mmcblk0p2|$uuid|" $BOOT/cmdline.txt
	echo "$uuid  /  ext4  defaults  0  0" >> $ROOT/etc/fstab
fi

# RPi 0 - fix: kernel panic
[[ $rpi == 0 ]] && echo -e 'force_turbo=1\nover_voltage=2' >> $BOOT/config.txt

# wifi
if [[ $ssid ]]; then
	echo -e "\n\e[36mSetup Wi-Fi ...\e[m"
	# profile
	profile="Interface=wlan0
	Connection=wireless
	IP=dhcp
	ESSID=\"$ssid\""
	[[ -n $wpa ]] && profile+="Security=$wpa
	Key=$password"
	echo $profile > "$ROOT/etc/netctl/$ssid"

	# enable startup
	dir="$ROOT/etc/systemd/system/netctl@$ssid.service.d"
	mkdir $dir
	echo '[Unit]
	BindsTo=sys-subsystem-net-devices-wlan0.device
	After=sys-subsystem-net-devices-wlan0.device' > "$dir/profile.conf"

	cd $ROOT/etc/systemd/system/multi-user.target.wants
	ln -s ../../../../lib/systemd/system/netctl@.service "netctl@$ssid.service"
	cd
fi

# get create-rune.sh
wget -qN --show-progress https://github.com/rern/RuneOS/raw/master/usr/local/bin/create-rune.sh -P $ROOT/usr/local/bin
chmod +x $ROOT/usr/local/bin/create-rune.sh

umount -l $BOOT && umount -l $ROOT && echo -e "\n$ROOT and $BOOT unmounted.\nMove to Raspberry Pi."

echo -e "\n\e[36mDone\e[m"
hr
