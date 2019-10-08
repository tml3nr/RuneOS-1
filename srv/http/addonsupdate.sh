#!/bin/bash

if (( $# == 0 )); then
	wget -qN --no-check-certificate https://github.com/rern/RuneAudio_Addons/raw/master/addonslist.php -P /tmp
	file=/tmp/addonslist.php
else
	file=/srv/http/addonslist.php
fi

list=( $( sed -n "/^'/ {
N;N;
s/=>/ /g
s/\s*\|'\|,//g
s/array.*version/ /
/array/ d
p}
" $file ) )
	
(( $# == 0 )) && rm /tmp/addonslist.php

declare -A download
ilength=${#list[@]}
for (( i = 0; i < $ilength; i+= 2 )); do
	download[${list[i]}]=${list[i+1]}
done

diraddons=/srv/http/data/addons
files=$( ls $diraddons )

declare -A current
for file in $files; do
	[[ $file == update || -z $( cat $diraddons/$file ) || $( cat $diraddons/$file ) == 1 ]] && continue
	current[$file]=$( cat $diraddons/$file )
done

count=0;
for KEY in "${!current[@]}"; do
	[[ ${current[$KEY]} != ${download[$KEY]} ]] && (( count++ ))
done

if (( $count > 0 )); then
	echo $count > $diraddons/update
else
	rm -f $diraddons/update
fi
