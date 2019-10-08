#!/usr/bin/python2
# coding: utf-8

import time , serial
from mpd import MPDClient

def MpdGetAudio(mpd):
    status = mpd.status()
    bitrate = status.get('audio')
    if (bitrate):
        audiotab = bitrate.split(':')
        if (audiotab[1] == "16"):
            return ("A,0")
        return ("A,1") 

def MpdGetVolume(mpd):
    status = mpd.status()
    volume = status.get('volume')
    return (volume)

if __name__ == '__main__':
    MPD_HOST = 'localhost'
    MPD_PORT = '6600'
    ser = serial.Serial('/dev/ttyAMA0', 2400)
    ser.isOpen()
    mpd = MPDClient()
    filtre = 1
    last_send = "A,0,0,0"

    mpd.connect(MPD_HOST, MPD_PORT)
    try:
        while True:
            bitrate = MpdGetAudio(mpd)
            time.sleep(0.1)
            print ("bitrate = " + bitrate)
            volume = MpdGetVolume(mpd)
            print ("volume = " + volume)
            send = str(bitrate) + "," + str(volume) + "," + str(filtre)
            #print(send)
            if (send != last_send):
                last_send = send
                ser.write(send.encode('utf-8'))
                print("send to DAC = " + send)
    except KeyboardInterrupt:
        mpd.close()
        mpd.disconnect()

    mpd.close()
    mpd.disconnect()