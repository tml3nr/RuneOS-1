#!/bin/bash

if (( $# > 0 )); then # stop
	curl -s -X POST 'http://localhost/pub?id=notify' -d '{"title":"AirPlay","text":"Switching back to MPD ...","icon":"airplay blink","delay":"10000"}'
	systemctl start mpd
	curl -s -X POST 'http://localhost/pub?id=airplay' -d 0
	exec( '/usr/bin/sudo /usr/bin/rm -f /srv/http/data/tmp/airplay*' );
else
	systemctl stop mpd
	curl -s -X POST 'http://localhost/pub?id=airplay' -d 1
fi
