### Image file to USB drive + SD card
- Download image file
- Decompress the file

**`ROOT` partition**
- Plug in USB drive
  - Blank:
    - Format: `ext4`
    - Label: `ROOT`
  - With existing data:
    - No need to change format of existing partition
    - Resize and create a new 4GB partition (anywhere - at the end, middle or start of the disk)
    - Format: `ext4`
    - Label: `ROOT`
- Click `ROOT` in **Files** to mount
```sh
# install package
apt install kpartx

# function for verify names
cols=$( tput cols )
showData() {
    printf %"$cols"s | tr ' ' -
    echo $1
    echo $2
    printf %"$cols"s | tr ' ' -
}

# specify image file
imagefile="/PATH/IMAGEFILE.img"

# map image file
kpartx -av "$imagefile"

# mount ROOT partition
mount /dev/mapper/loop0p2 /mnt

# get ROOT partition and verify
ROOT=$( df | grep ROOT | awk '{print $NF}' )
showData "$( df -h | grep ROOT )" "ROOT = $ROOT"

# copy to usb drive
cp -rp /mnt $ROOT

# unmount
umount /mnt
```

**`BOOT` partition**
- Insert Micro SD card
- Format to `fat32` and label as `BOOT`
- Click `BOOT` in **Files** to mount
```sh
# mount BOOT partition
mount /dev/mapper/loop0p1 /mnt

# get BOOT partition and verify
BOOT=$( df | grep BOOT | awk '{print $NF}' )
showData "$( df -h | grep BOOT )" "BOOT = $BOOT"

# copy to usb drive
cp -r /mnt $BOOT

# unmount
umount /mnt

# unmap image file
kpartx -dv "$imagefile"
```

**Setup USB as root partition**
```sh
# get UUID and verify
dev=$( df | grep ROOT | awk '{print $1}' )
uuid=$( /sbin/blkid | grep $dev | cut -d' ' -f3 | tr -d '"' )
showData "$( df -h | grep ROOT )" $uuid

# replace root device
sed -i "s|/dev/mmcblk0p2|$uuid|" $BOOT/cmdline.txt

# append to fstab
echo "$uuid  /  ext4  defaults  0  0" >> $ROOT/etc/fstab
```

**Done**

### Raspbian partitions (USB bootable)

| Type    | No. | Label  | Format | Size  | flag |
|---------|-----|--------|--------|-------|------|
| unalloc | #1  |        |        | 4MB   |      |
| primary | #2  | boot   | fat32  | 256MB | lba  |
| primary | #3  | rootfs | ext4   | 4GB   |      |
