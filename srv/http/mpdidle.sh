#!/bin/bash

trap exit 2

while :; do
	mpc idle | tr -d '\n' | curl -s -X POST 'http://127.0.0.1/pub?id=idle' -d '{ "changed": "'"$(</dev/stdin)"'" }'
done
