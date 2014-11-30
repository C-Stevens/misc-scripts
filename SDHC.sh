#!/bin/bash

card_mount="" # Location of SDHC (e.g /dev/sdb)
img_dir="" # Location of saved SDHC images

if [ -z $card_mount ]; then
	echo "card_mount path not specified. Exiting..."
	exit 1
fi
if [ -z $img_dir ]; then
	echo "img_dir path not specified. Exiting..."
	exit 1;
fi

if [ $EUID -ne 0 ]; then # Run as root if not already
	exec sudo -- "$0" "$@"
fi

case "$1" in
	[bB]ackup )
		echo "Creating SDHC image..."
		name=$(date | sed 's/ /-/g')
		dd if="$card_mount" of="$img_dir/$name.img"
		if [ $? -ne 0 ]; then
			echo "Failed to create image"
			exit 1
		fi
		echo "Image saved as $name.img"
		;;
	[fF]lash )
		if [ "$2" != "-f" ]; then # Check for flags
			read -p "[WARNING!] This will destroy all data on SDHC. Proceed? (y/n): "  opt
			if [ $opt != "y" ]; then
				exit 1
			fi
		fi
		if [ "$2" == "-f" ]; then
			echo "Flashing $3 to SDHC..."
			dd if="$img_dir/$3" of="$card_mount"
			if [ $? -ne 0 ]; then
				echo "Failed to flash card"
				exit 1
			fi
		else
			echo "Flashing $2 to SDHC..."
			dd if="$img_dir/$2" of="$card_mount"
			if [ $? -ne 0 ]; then
				echo "Failed to flash card"
				exit 1
			fi
		fi
		echo "Flash complete"
		;;
	* )
		echo $"Usage: $0 {backup|flash}"
		exit 1
esac
