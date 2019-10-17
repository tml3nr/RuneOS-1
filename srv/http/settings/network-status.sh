#!/bin/bash

readarray -t lines <<<"$( ip a | grep -v 'LOOPBACK\|link\|valid' )"

for line in "${lines[@]}"; do
	ini=${line:3:2}
	if [[ $ini == et || $ini == wl ]]; then
		if [[ $next == 1 ]]; then
			list="$list\n"
			next=0
		fi
		inf=$( echo $line | cut -d: -f2 | tr -d ' ' )
		ip r | grep -q "default.*$inf.*dhcp" && dhcp=dhcp
		[[ $ini == wl ]] && ssid=$( iwgetid $inf -r )
		if [[ $( echo $line | grep 'state UP' ) ]]; then
			up=up
			gw=$( ip r | grep "default.*$inf" | awk '{print $3}' )
		fi
		list="$list$inf^^$up^^"
		next=1
	elif [[ $next ]]; then
		ip=$( echo $line | awk '{print $2}' | cut -d'/' -f1 )
		list="$list$ip^^$ssid^^$gw^^$dhcp\n"
		next=0
		dhcp=
		ssid=
		next=
		up=
		gw=
	fi
done

printf "${list:0:-2}"
