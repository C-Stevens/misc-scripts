#!/bin/bash

##Required/recommended packages:
#    mailutils
#    msmtp
#    msmtp-mta

currentIp=$(cat ~/ip.log)
grabbedIp=$(wget -O - -q -nv --delete-after www.icanhazip.com)
email="mail@yourdomain.com"
if [ "$currentIp" != "$grabbedIp" -n -a "$grabbedIp" ] ;
then
	echo -e As of $(date): '\n'IP address has changed from $currentIp to $grabbedIp | mail -s "IP ADDRESS CHANGE" $email
	echo $grabbedIp > ~/ip.log
fi