#!/bin/bash

profile=$1

revision=$( cat /proc/cpuinfo | grep '^Revision' | tail -c7 )

setConfig() {
	ifconfig eth0 mtu $1
	ifconfig eth0 txqueuelen $2
	[[ -n $3 ]] && echo $3 > /proc/sys/vm/swappiness
	[[ -n $4 && ${revision:3:2} == '08' ]] && echo $4 > /proc/sys/kernel/sched_latency_ns
}

if [[ $profile == default ]]; then # default
	setConfig 1500 1000 60 6000000
elif [[ $profile == RuneAudio ]]; then # default Rune
	setConfig 1500 1000 0 4500000
elif [[ $profile == ACX ]]; then
	setConfig 1500 4000 0 3500075
elif [[ $profile == Orion ]]; then
	setConfig 1000 4000 20 1000000
elif [[ $profile == OrionV2 ]]; then
	setConfig 1000 4000 0 2000000
elif [[ $profile == OrionV3 ]]; then
	setConfig 1000 4000 0
elif [[ $profile == Um3ggh1U ]]; then
	setConfig 1500 1000 0 3700000
fi
