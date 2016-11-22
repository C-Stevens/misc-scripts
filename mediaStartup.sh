#!/bin/bash
# This is the startup script for the root user of one of my machines. This machine has two encrypted drives
# that take too long to open on the hardware at boot time so they are opened by cron and this script.
                                                                                                                                                                                                                                                                               
echo 'Startup script for '$USER' running on '$(date)                                                                                                                                                                                                                           

# The following vars expect a drive UUID
main_drive=                                                                                                                                                                                                                                
mirror_drive=                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                               
echo 'Checking for existence of '$main_drive'...'                                                                                                                                                                                                                              
count=0                                                                                                                                                                                                                                                                        
while [ $count -ne 5 ]; do # Try 5 times to mount the drive                                                                                                                                                                                                                    
        blkid | grep $main_drive &> /dev/null                                                                                                                                                                                                                                  
        if [ $? -eq 0 ]; then                                                                                                                                                                                                                                                  
                echo 'Drive found, continuing.'                                                                                                                                                                                                                                
                break                                                                                                                                                                                                                                                          
        fi                                                                                                                                                                                                                                                                     
        sleep 5                                                                                                                                                                                                                                                                
        let count+=1                                                                                                                                                                                                                                                           
done                                                                                                                                                                                                                                                                           
if [ $count -eq 5 ]; then # Drive not found                                                                                                                                                                                                                                    
        echo $main_drive' could not be found after 5 tries.'                                                                                                                                                                                                                   
        exit 1                                                                                                                                                                                                                                                                 
fi
echo 'Opening and mounting...'
cryptsetup luksOpen /dev/disk/by-uuid/$main_drive --key-file=/root/keys/$main_drive.key 2tb
mount -t ext4 /dev/mapper/2tb /media/External -o defaults,errors=remount-ro

echo 'Checking for existence of '$mirror_drive'...'
count=0
while [ $count -ne 5 ]; do # Try 5 times to mount the drive
        blkid | grep $mirror_drive &> /dev/null
        if [ $? -eq 0 ]; then
                echo 'Drive found, continuing.'
                break
        fi
        sleep 5
        let count+=1
done
if [ $count -eq 5 ]; then # Drive not found
        echo $mirror_drive' could not be found after 5 tries.'
        exit 1
fi
echo 'Opening and mounting...'
cryptsetup luksOpen /dev/disk/by-uuid/$mirror_drive --key-file=/root/keys/$mirror_drive.key 4tb
mount -t ext4 /dev/mapper/4tb /media/External-mirror -o defaults,errors=remount-ro

echo 'Executing post-mount commands...'
# Drive-dependant commands go here
