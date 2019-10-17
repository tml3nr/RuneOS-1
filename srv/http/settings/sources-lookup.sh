#!/bin/bash

lines=$( nmblookup -S WORKGROUP | sed -n '/^Looking/ {N;p}' )
readarray -t lines <<<"$lines"
for line in "${lines[@]}"; do
	if [[ ${line:0:7} == Looking ]]; then
		ip=$( echo $line | awk '{print $NF}' )
	elif [[ ${line:0:8} != 'No reply' ]]; then
		name=$( echo $line | awk '{print $1}' )
		shares+="$( echo '' | smbclient -L "$name" | grep '^\s\+.*Disk' | grep -v '\$' | sed "s|^\s*|$name^^$ip^^|; s/\s*Disk\s*$//" )\n"
	fi
done

shares=$( echo -e "$shares" | awk NF | sort )

printf -- "$shares"
