#!/bin/bash

{

dirsystem=/srv/http/data/system

# for startup udev before /dev/sda1 ounted
[[ ! -e $dirsystem/audiooutput ]] && exit

aplay=$( aplay -l | grep '^card' )

# reenable on-board audio if nothing available for aplay
if [[ -z $aplay ]]; then
	sed -i 's/dtparam=audio=.*/dtparam=audio=on/' /boot/config.txt
	shutdown -r now
fi

file=/etc/mpd.conf
mixertype=$( grep mixer_type $file | cut -d'"' -f2 )
mpdconf=$( sed '/audio_output/,/}/ d' $file ) # remove all outputs

readarray -t lines <<<"$aplay"
for line in "${lines[@]}"; do
	device=$( echo $line | sed 's/card \(.*\):.*device \(.*\):.*/hw:\1,\2/' )
	card=${device:3:1}
	if [[ $mixertype == none ]]; then
		scontents=$( amixer -c $card scontents | grep -B1 'pvolume' | grep 'Simple' | awk -F"['']" '{print $2}' )
		readarray -t mixers <<<"$scontents"
		for mixer in "${mixers[@]}"; do
			amixer -c $card sset "$mixer" 0dB
		done
	fi
	subdevice=${device: -1}
	name=$( echo $line | awk -F'[][]' '{print $2}' )
	nameL=$( echo "$aplay" | grep "$name" | wc -l )
	if (( $nameL > 1 ));then
		sysname="$name"_$(( subdevice + 1 ))
	else
		sysname=$name
	fi
	[[ $sysname == 'bcm2835 ALSA_3' ]] && continue
	
	i2sfile="/srv/http/settings/i2s/$sysname"
	[[ -e "$i2sfile" ]] && mixer_control=$( grep mixer_control "$i2sfile"  | cut -d: -f2- )
	
	mpdconf+='

audio_output {
	name              "'$sysname'"
	device            "'$device'"
	type              "alsa"
	auto_resample     "no"
	auto_format       "no"'
	
	if [[ -n $mixer_control ]]; then
		mpdconf+='
	mixer_control     "'$mixer_control'"
	mixer_device      "hw:'$card'"'
	
	fi
	
	if [[ -e /srv/http/data/system/mpd-dop && ${sysname:0:-2} != 'bcm2835 ALSA' ]]; then
		mpdconf+='
	dop               "yes"'
	
	fi
	
	mpdconf+='
}'

done

echo "$mpdconf" > $file

systemctl restart mpd mpdidle

if [[ -e $dirsystem/audiooutput0 ]]; then
	mv -f $dirsystem/audiooutput{0,} &> /dev/null
	sysname=$( cat $dirsystem/audiooutput )
else
	mv -f $dirsystem/audiooutput{,0} &> /dev/null
	echo $sysname > $dirsystem/audiooutput
fi

file="/srv/http/settings/i2s/$sysname"
[[ -e "$file" ]] && name=$( grep extlabel "$file" | cut -d: -f2- ) || name=$sysname

curl -s -X POST 'http://127.0.0.1/pub?id=notify' -d '{ "title": "Audio Output Switched", "text": "'"$name"'", "icon": "output" }'
curl -s -X POST 'http://127.0.0.1/pub?id=page' -d '{ "p": "mpd" }'

} &
