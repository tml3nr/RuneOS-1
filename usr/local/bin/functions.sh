#!/bin/bash

download() {
    tcolor() {
        echo -e "  \e[38;5;6m\e[48;5;0m$1\e[0m" "$2"
    }
    echo -e "\nRaspberry Pi:"
    tcolor 1 'RPi 0-1'
    tcolor 2 'RPi 2-3'
    tcolor 3 'RPi 3+'
    tcolor 4 'RPi 4'
    read -rn 1 -p "Select: " rpi; echo
    if [[ $rpi == 1 ]]; then
        file=ArchLinuxARM-rpi-latest.tar.gz
    elif [[ $rpi == 2 ]]; then
        file=ArchLinuxARM-rpi-2-latest.tar.gz
    elif [[ $rpi == 3 ]]; then
        file=ArchLinuxARM-rpi-3-latest.tar.gz
    elif [[ $rpi == 4 ]]; then
        file=ArchLinuxARM-rpi-4-latest.tar.gz
    else
        echo $rpi not available.
        download
    fi
    if [[ -n $file ]]; then
        echo -e "\nConnecting ..."
        wget -qN --show-progress http://os.archlinuxarm.org/os/$file
    fi
}

cols=$( tput cols )
showData() {
    printf %"$cols"s | tr ' ' -
    [[ -n $3 ]] && echo -e "$1\n$2$3" || echo $2 not found.
    printf %"$cols"s | tr ' ' -
}
