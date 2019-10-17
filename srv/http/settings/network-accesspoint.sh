#!/bin/bash

passphrase="$1"
ip=$2
range=$3

if [[ -n $passphrase ]]; then
	sed -i -e "/wpa\|rsn_pairwise/ s/^#\+//
	" -e "s/\(wpa_passphrase=\).*/\1$passphrase/
	" /etc/hostapd/hostapd.conf
else
	sed -i -e "/wpa\|rsn_pairwise/ s/^/#/
	" /etc/hostapd/hostapd.conf
fi

sed -i "s/^\(dhcp-range=\).*/\1$range/
	s/^\(dhcp-option-force=option:router,\).*/\1$ip/
	s/^\(dhcp-option-force=option:dns-server,\).*/\1$ip/
	" /etc/dnsmasq.conf
	
systemctl restart hostapd dnsmasq
