#!/bin/bash

[[ -n $1 ]] && wlan=$1 || wlan=wlan0

ifconfig $wlan up

netctllist=$( netctl list | grep -v eth | sed 's/^\s*\**\s*//' )
if [[ -n $netctllist ]]; then
	readarray -t netctllist_ar <<<"$netctllist"
	# pre-scan saved profile to force display hidden ssid
	for name in "${netctllist_ar[@]}"; do
		grep -q '^Hidden=yes' "/etc/netctl/$name" && iwlist $wlan scan essid "$name" &> /dev/null
	done
fi

connectedssid=$( iwgetid $wlan -r )

iwlistscan=$( iwlist $wlan scan | grep '^\s*Qu\|^\s*En\|^\s*ES\|WPA' | sed 's/^\s*//' )
readarray -t iwlistscan_ar <<<"$iwlistscan"
for line in "${iwlistscan_ar[@]}"; do
	ini=${line:0:2}
	if [[ $ini == Qu ]]; then
		if [[ -n $ssid ]]; then
			list="$list$db^^$ssid^^$encryption^^$wpa^^$wlan^^$connected^^$profile^^$gw_ip\n"
		fi
		signal=
		quality=
		db=
		ssid=
		encryption=
		wpa=
		profile=
		db=$( echo $line | cut -d= -f3 )
	elif [[ $ini == En ]]; then
		encryption=$( echo $line | cut -d':' -f2 )
	elif echo $line | grep -q WPA; then
		wpa=wpa
	elif [[ $ini == ES ]]; then
		ssid=$( echo $line | cut -d':' -f2 | sed 's|\\x00||g' )
		ssid=${ssid:1:-1}
		if [[ $ssid == $connectedssid ]]; then
			connected=connected
			gw_ip=$( ip r | grep "default.*$wlan" | awk '{print $3"^^"$9}' )
		else
			connected=
			gw_ip=
		fi
		if [[ -n $netctllist ]]; then
			for name in "${netctllist_ar[@]}"; do
				[[ $ssid == $name ]] && profile=netctllist_ar
			done
		fi
	fi
done
# last one
if [[ -n $ssid ]]; then
	list="$list$db^^$ssid^^$encryption^^$wpa^^$wlan^^$connected^^$profile^^$gw_ip"
fi

list=$( echo -e "$list" | awk NF | sort )

printf -- "$list"
