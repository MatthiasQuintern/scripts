#!/bin/bash
# Matthias Quintern, 2022
# Mount usb device at /media/usb-model via systemd-mount
logfile=/home/matth/.tmp/mount.log

partition=$1
partition_nr=$(echo "${partition: -1}")
device=$(echo $partition | rev | cut -c2- | rev)  # /dev/sdX
model=$(lsblk $device -o MODEL | awk "NR==2")  # model of /dev/sdX
dir=$(echo "/media/usb-$model-$partition_nr" | sed "s/ /_/g")  # /media/usb-model-pt.nr


# ACTION should be provided by udev
if [ $ACTION = "add" ]; then
    mkdir -p $dir
    echo "$(date +"%F - %T:") mounting $partition at $dir" >> $logfile
    systemd-mount --no-block --automount=yes --timeout-idle-sec=180 --collect --options=uid=1000,gid=985 $partition $dir ||
    echo "$(date +"%F - %T:") could not mount $partition at $dir" >> $logfile

elif [ $ACTION = "remove" ]; then
    sleep 4
    for mtp in $(ls -p /media | grep /); do
        echo "$(date +"%F - %T:") $partition was removed, removing unused mountpoints in /media: /media/$mtp" >> $logfile
        rm -d /media/$mtp || echo "$(date +"%F - %T:"): could not remove /media/$mtp" >> $logfile
    done
fi
