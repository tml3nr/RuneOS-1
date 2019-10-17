#!/bin/bash

result=$( df -h | grep /mnt/MPD/ | awk '{print $6" <a class=\"green\">&ensp;&bull;&ensp;</a><gr>"$1"</gr>&ensp;"$2"B&ensp;"$4"B free"}' )
devices=( $( fdisk -l -o Device | grep '^/dev/sd' ) )
devices+=( $( grep '/mnt/MPD/NAS/' /etc/fstab | awk '{print $2}' | sed 's/\\040/ /' ) ) # convert escaped space character "\040" in fstab
if [[ -z $devices ]]; then
	printf -- "$result"
	exit
fi

for device in "${devices[@]}"; do
	if [[ "$result" != *"$device"* ]]; then
		if [[ ${device:0:4} == '/dev' ]]; then
			label=$( e2label $device )
			result+="\n${device}^^/mnt/MPD/USB/$label"
		else
			label=$( grep $device /etc/fstab | awk '{print $1}' | sed 's/\\040/ /' )
			result+="\n${label}^^$device"
		fi
	fi
done

printf -- "$result"
