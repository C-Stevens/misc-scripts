#!/bin/bash
# Usage:
#	bash mount-encFlash.sh unmount/mount
# Simple script to (dis)mount a flash drive based on uuid and
# then (dis)mount a TrueCrypt container on that drive's root.
# This script requires the user running it to either be root,
# or be in the sudoers file.

drive_uuid=""
drive_mount=""
enc_mount=""
tc_filename=""

if [ $EUID -ne 0 ]; then
	exec sudo -- "$0" "$@"
fi
if [ "$1" == "mount" ]; then
	echo "Mounting..."
	mkdir -p $drive_mount
	mkdir -p $enc_mount
	mount -t ntfs-3g -o rw -U $drive_uuid $drive_mount
	if [ $? -ne 0 ]; then
		echo "Drive mounting failed."
		exit
	fi
	cryptsetup --type tcrypt open $drive_mount/$tc_filename usbenc
	mount -t ntfs-3g -o rw /dev/mapper/usbenc $enc_mount
	if [ $? -ne 0 ]; then
		echo "Failed to mount TrueCrypt container."
		echo "Finished with errors."
		exit
	else
		echo "Mount successful."
		exit
	fi

elif [ "$1" == "unmount" ]; then
	echo "Unmounting..."
	umount $enc_mount
	if [ $? -ne 0 ]; then
		echo "Failed to unmount drive."
		exit
	else
		sleep 1 # Sleep buffers to give drives time to properly unmount and clean up
	fi
	cryptsetup close usbenc
	sleep 1
	umount $drive_mount
	if [ $? -ne 0 ]; then
		echo "Failed to unmount TrueCrypt container."
		echo "Finished with errors."
		exit
	else
		echo "Unmount successful."
	fi
else
	echo "Bad arg. Accepted args are: mount, unmount"
fi
