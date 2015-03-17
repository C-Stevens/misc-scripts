#!/bin/bash
# Place in /etc/NetworkManager/dispatcher.d/, the script *must* be set to executable!
## Launches a vpn at random from the specified pool, clears out old vpn tun0 cruft from
## NetworkManager, then gives  a small popup in KDE with helpful network information and
## a connection success message.
INT=$1
STATUS=$2
nuser= # User to issue dialoge as
ping_test= # URL to ping for verifying internet connectivity
idle_time= # Amount of time (in seconds) to wait before retrying the vpn connection upon ping failure
interfacePool=() # Pool of interfaces to check
ssidBlacklist=() # Pool of SSIDs that the VPN should not connect over

checkInterfaces() {
	# Returns 1 if $INT isn't in the interface pool of NetworkManager reports it down.
	# Returns 0 if $INT is in the interface pool and is reported as up in $STATUS
	for (( i=0; i<${#interfacePool[@]}; i++ )); do
		if [ "${interfacePool[$i]}" == "$INT" -a "$STATUS" == "up" ]; then
			return 0
		fi
	done
	return 1
}

checkSSID() {
	# Returns 1 if the machine has connected to a blacklisted SSID and VPN connection should not be made, or SSID cannot be determined
	# Returns 0 if the machine is not connected to a blacklisted SSID and can connect to VPN
	currentSSID=$(nmcli con show | grep -v -- "--" | tail -1 | awk '{print $1}')
	if [ ! -z $currentSSID ]; then
		for(( i=0; i<${#ssidBlacklist[@]}; i++ )); do
			if [ "${ssidBlacklist[$i]}" == "$currentSSID" ]; then
				return 1
			fi
		done
		return 0
	else # If the SSID cannot be determined, stay safe and do not connect to VPN
		return 1
	fi
}

if checkInterfaces && checkSSID; then # If one of the interfaces goes up and the SSID we're connected to isn't blacklisted
        # Define all exit values here. Entires must be added to NetworkManager, after they are added you can retreive their uuid with: nmcli con show
        exit1='' # To demonstrate the configurability of the server pool, this exit is left out by default
        exit2=''
        exit3=''
        exit4=''
        serverPool=("$exit2" "$exit3" "$exit4") # Allow only exits 2, 3, and 4 to be chosen as the VPN exit
        RANDOM=$$$(date +%s)
        choice=${serverPool[$RANDOM % ${#serverPool[@]} ]}
        # Buffer to allow the interface to become active after its been brought up, ping loop checks for internet connectivity
        while true; do
                ping -c 1 $ping_test > /dev/null
                if [ $? -eq 0 ]; then
                        nmcli con up uuid $choice
                        break
                else
                        sleep $idle_time
                        continue
                fi
        done
        # Gets a list of old vpn tun0 connections that aren't in use and removes them
        scrap_uuids=($(nmcli con show | grep "^tun0" | grep -- "--" | awk '{print $2}'))
        if [ ${#scrap_uuids[@]} -ne 0 ]; then
                nmcli con delete uuid $(printf -- '%s\n' "${scrap_uuids[@]}")
        fi
        # Transalate uuid choice into human-friendly terms for the pop-up message
        if [ "$choice" = "$exit2" ]; then
                exit="The Second Exit country"
        elif [ "$choice" = "$exit3" ]; then
                exit="The Third Exit country"
        elif [ "$choice" = "$exit4" ]; then
                exit="The Fourth Exit country"
        fi
        # Check if the vpn connection is activated
	sleep 3 # Buffer to allow NetworkManager to get finished
        nmcli con show uuid $choice | grep STATE | grep activated > /dev/null
        if [ $? -eq 0 ]; then
		# Gather pop-up data
		ip=$(curl https://icanhazip.com 2>/dev/null)
	        hostname=$(dig -x "$ip" +short)
		if [ -z $hostname ]; then
			hostname="Hostname could not be determined"
		else
			hostname="Your hostname is: <b>$hostname</b>"
		fi
		# Set display and DBUS env values so root can display the KDE pop-up properly
		dbus_session_file=/home/$nuser/.dbus/session-bus/$(cat /var/lib/dbus/machine-id)-0
		if [ -e "$dbus_session_file" ]; then
			. "$dbus_session_file"
			export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
		fi
		su -c "notify-send -t 5000 --icon=object-locked 'VPN Connected!' 'Your exit address is in <b>$exit</b><br>Your ip is: <b>$ip</b><br>$hostname'" $nuser
        fi
fi
