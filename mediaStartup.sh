#!/bin/bash
# This is the startup script for the root user of one of my machines. This machine has two encrypted drives
# that take too long to open on the hardware at boot time so they are opened by cron and this script.
                                                                                                                                                                                                                                                                               
MOUNT_ROOT_PATH="/media"
DEFAULT_MAIN_DRIVE_UUID=
DEFAULT_MIRROR_DRIVE_UUID=
MAIN_DRIVE_DEVICE_NAME="main"
MIRROR_DRIVE_DEVICE_NAME="mirror"
MAIN_DRIVE_MOUNT_DIR=$MOUNT_ROOT_PATH"/External"
MIRROR_DRIVE_MOUNT_DIR=$MOUNT_ROOT_PATH"/External-mirror"

# Check for user specified args, re-assign as necessary
MAIN_DRIVE_UUID=${1:-$DEFAULT_MAIN_DRIVE_UUID}
MIRROR_DRIVE_UUID=${2:-$DEFAULT_MIRROR_DRIVE_UUID}

function validateDirs {
        echo "Validating valid mounting directories.."
        
        echo -ne "\tChecking validity of root mounting directory... "
        if [ ! -d $MOUNT_ROOT_PATH ]; then
                echo "Directory doesn't exist!"
                echo -e "\tFailed to validate root directory at $MOUNT_ROOT_PATH"
                return 1 # Return failure code
        fi
        echo "Done"

        echo -ne "\tChecking validity of main drive mounting directory... "
        if [ ! -d $MAIN_DRIVE_MOUNT_DIR ]; then
                echo "Directory doesn't exist!"
                echo -e "\tFailed to validate main drive mounting diretory at $MAIN_DRIVE_MOUNT_DIR"
                return 1 # Return failure code
        fi
        echo "Done"

        echo -ne "\tChecking validity of mirror drive mounting directory... "
        if [ ! -d $MIRROR_DRIVE_MOUNT_DIR ]; then
                echo "Directory doesn't exist!"
                echo -e "\tFailed to validate mirror drive mounting directory at $MIRROR_DRIVE_MOUNT_DIR"
                return 1
        fi
        echo "Done"
}

function mountDrive {
        # mountDrive UUID MountingDir DeviceName
        driveUUID=$1
        driveMountPath=$2
        driveName=$3
        echo "Processing drive $driveUUID"
        # Ensure the drive is visible to the machine
        echo -en "\tChecking for existence of drive... "
        drivePingCount=1 # Intentionally offset this by one, as the initial command will count as a ping
        drivePingMax=5
        while (( drivePingCount != drivePingMax )); do # Try to find the drive, sleeping 5 seconds between attempts
                blkid | grep $driveUUID &> /dev/null
                if [ $? -eq 0 ]; then
                        echo "Found"
                        break
                fi
                # Drive not found, keep trying
                echo "Not found! Trying again in 5 seconds ($drivePingCount/$drivePingMax)"
                sleep 5
                let drivePingCount+=1
                echo -ne "\tLooking again for drive... "
        done
        if (( drivePingCount == drivePingMax)); then
                echo "Not found! ($drivePingCount/$drivePingMax)"
                echo -e "\tDrive could not be found after $drivePingMax attempts."
                return 1 # Return failure code
        fi
        
        # Ensure we have a crypto key for this drive
        echo -en "\tLooking for the existence of a crypto key for this drive... "
        if [ ! -e "/root/keys/$driveUUID.key" ]; then
                echo "Not found!"
                echo -e "\tKey for this drive could not be found at /root/keys/$driveUUID.key"
                return 1 # Return failure code
        fi
        echo "Found"

        # Open the device and mount the drive
        echo -en "\tOpening the encrypted volume... "
        cryptsetup luksOpen /dev/disk/by-uuid/$driveUUID --key-file=/root/keys/$driveUUID.key $driveName
        if [ $? -ne 0 ]; then
                return 1 # Return failure code
        fi
        echo "Done"
        echo -en "\tMounting the device... "
        mount /dev/mapper/$driveName $driveMountPath -o defaults,errors=remount-ro
        if [ $? -ne 0 ]; then
                return 1 # Return failure code
        fi
        echo "Done"

}

validateDirs
if [ $? -eq 1 ]; then
        echo "Could not validate mounting directories."
        exit 1
fi

mountDrive $MAIN_DRIVE_UUID $MAIN_DRIVE_MOUNT_DIR $MAIN_DRIVE_DEVICE_NAME
if [ $? -eq 1 ]; then
        echo "Errors occured while attempting to mount main drive."
        exit 1
fi
mountDrive $MIRROR_DRIVE_UUID $MIRROR_DRIVE_MOUNT_DIR $MIRROR_DRIVE_DEVICE_NAME
if [ $? -eq 1 ]; then
        echo "Errors occured while attempting to mount mirror drive."
        exit 1
fi

exit 0
