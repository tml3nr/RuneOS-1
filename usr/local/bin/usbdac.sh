#!/bin/bash

dirsystem=/srv/http/data/system

# for startup udev before /dev/sda1 mounted
[[ ! -e $dirsystem/audiooutput ]] && exit

/srv/http/settings/mpdconf.sh

if (( $# > 0 )); then
	mv -f $dirsystem/audiooutput{,0}
	name=$( aplay -l | grep card | tail -1 | awk -F'[][]' '{print $2}' )
	echo $name > $dirsystem/audiooutput
else
	mv -f $dirsystem/audiooutput{0,}
	name=$( cat $dirsystem/audiooutput )
	file="/srv/http/settings/i2s/$name"
	[[ -e "$file" ]] && name=$( grep extlabel "$file" | cut -d: -f2- )
fi

curl -s -X POST 'http://localhost/pub?id=notify' -d '{ "title": "Audio Output Switched", "text": "'"$name"'", "icon": "output" }'
curl -s -X POST 'http://localhost/pub?id=page' -d '{ "p": "mpd" }'
