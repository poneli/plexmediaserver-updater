#!/bin/bash
#### Description: Upgrades plexmediaserver for debian/ubuntu based distros
####
#### Written by: poneli on 2021 October 3
#### Published on: https://github.com/poneli/
#### =====================================================================
#### <VARIABLES>
latestversion=$(curl -s -L https://forums.plex.tv/t/plex-media-server/30447/10000 | awk '/<p><strong>Plex Media Server/ {print $4}' | tail -1)
currentversion=$(dpkg -s plexmediaserver | awk -F'[- ]' '/^Version:/ { print $2 }')
plextoken="PLEXTOKEN-HERE" # Find your plex token -> (https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)
downloadfolder="/change/me/example/directory" # No trailing slash
#### </VARIABLES>
if [[ $EUID -gt 0 ]]; then
	printf "Run with sudo... \n"
	exit
fi

if [[ $latestversion > $currentversion ]]; then
	printf "Downloading plexmediaserver to %s... \n" "$downloadfolder"
	wget -q -O plexmediaserver-$latestversion.deb "https://plex.tv/downloads/latest/5?channel=8&build=linux-x86_64&distro=debian&X-Plex-Token=$plextoken" 2>&1 >/dev/null
	printf "Stopping plexmediaserver... \n"
	systemctl stop plexmediaserver.service 2>&1 >/dev/null
	printf "Installing update... \n"
	dpkg -i plexmediaserver-$latestversion.deb 2>&1 >/dev/null
	if [[ $(dpkg -s plexmediaserver | awk -F'[- ]' '/^Version:/ { print $2 }') = $latestversion ]]; then
	  printf "plexmediaserver updated successfully from version %s to %s... \n" "$currentversion" "$latestversion"
	  printf -- "%(%Y-%m-%d %H:%M:%S)T [SUCCESS] plexmediaserver updated to %s... \n" "$(date +%s)" "$latestversion" | tee -a $downloadfolder/update.log >/dev/null
	  printf "Starting plexmediaserver... \n"
	  systemctl start plexmediaserver.service 2>&1 >/dev/null
	  printf "Cleaning up %s... \n" "$downloadfolder"
	  rm -f $downloadfolder/*.deb
	else
	  printf "Installation of plexmediaserver %s failed... \nTerminated... \n" "$latestversion"
	  printf -- "%(%Y-%m-%d %H:%M:%S)T [ERROR] plexmediaserver %s update failed... \n" "$(date +%s)" "$latestversion" | tee -a $downloadfolder/update.log >/dev/null
	fi
else
	printf "plexmediaserver %s is already installed... \nTerminated... \n" "$latestversion"
	printf -- "%(%Y-%m-%d %H:%M:%S)T [INFO] plexmediaserver %s is already installed... \n" "$(date +%s)" "$latestversion" | tee -a $downloadfolder/update.log >/dev/null
fi
