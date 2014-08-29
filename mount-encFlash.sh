#!/bin/bash
# Usage:
#	bash ./mount-encFlash.sh unmount/mount
# Simple script to (dis)mount a flash drive based on uuid and
# then (dis)mount a TrueCrypt container on that drive's root.
# This script requires the user running it to either be root,
# or be in the sudoers file.

drive_uuid=""
drive_mount=""
enc_mount=""
tc_filename=""
fs=""

if [ $EUID -ne 0 ]; then # Check if the user is running script as root. If not, do so
	exec sudo -- "$0" "$@"
fi
case "$1" in
	[mM]ount )
		echo "Mounting..."
		mkdir -p "$drive_mount"
		mkdir -p "$enc_mount"
		mount -t "$fs" -o rw -U "$drive_uuid" "$drive_mount"
		if [ $? -ne 0 ]; then
			echo "Drive mounting failed."
			exit 1
		fi
		cryptsetup --type tcrypt open "$drive_mount"/"$tc_filename" usbenc
		mount -t "$fs" -o rw /dev/mapper/usbenc "$enc_mount"
		if [ $? -ne 0 ]; then
			echo "Failed to mount TrueCrypt container."
			echo "Finished with errors."
			exit 1
		fi
		echo "Mount successful."
		;;
	[uU]nmount )
		echo "Unmounting..."
		umount "$enc_mount"
		if [ $? -ne 0 ]; then
			echo "Failed to unmount drive."
			exit 1
		fi
		sleep 1 # Sleep buffer to avoid device-mapper "resource busy" error
		cryptsetup close usbenc
		umount "$drive_mount"
		if [ $? -ne 0 ]; then
			echo "Failed to unmount TrueCrypt container."
			echo "Finished with errors."
			exit 1
		fi	
		echo "Unmount successful."
		;;
	* )
		echo $"Usage: $0 {mount|unmount}"
		exit 1
esac
