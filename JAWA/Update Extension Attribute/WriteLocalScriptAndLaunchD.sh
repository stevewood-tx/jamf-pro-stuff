#!/bin/bash

#########################################################################################
#
# Copyright (c) 2023, JAMF Software, LLC.  All rights reserved.
#
# THE SOFTWARE IS PROVIDED "AS-IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
# JAMF SOFTWARE, LLC OR ANY OF ITS AFFILIATES BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF OR OTHER DEALINGS IN
# THE SOFTWARE, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# CONSEQUENTIAL OR PUNITIVE DAMAGES AND OTHER DAMAGES SUCH AS LOSS OF USE, PROFITS,
# SAVINGS, TIME OR DATA, BUSINESS INTERRUPTION, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES.
#
#########################################################################################
#
#
# Be sure to set the path where you want to store the local script on the endpoint
# Set the name of your LaunchDaemon and the path to the plist where you are storing 
# the computer ID and EA ID locally on the device.
# 
# Make sure to set the webhook URL, user, pass, and plist path in the heredoc section
#
#########################################################################################
# set the below variables to the locations and names you want
local_script="/Library/YourCompany/update_cache_stats.sh"
launch_daemon="/Library/LaunchDaemons/com.yourcompany.updateCacheStats.plist"
data_plist="/Library/Application Support/JAMF/com.yourcompany.computer-info.plist"
EA_ID="$4" # ID of our Extension Attribute as Parameter 4 in our Policy

#write out EA 
/usr/bin/defaults write "$data_plist" eaID -string $EA_ID


# check for our script folder. Be sure to update the path if you changed the variables above
if [[ ! -d "/Library/YourCompany" ]]; then
	mkdir -p "/Library/YourCompany"
fi

# write out script using Here doc
# be sure to update the variables for your JAWA server and change the plist_path to match where you want to store
# these values
tee "$local_script" << "EOF"
#!/bin/bash

#set variables
webhook_url="https://yourjawaserver.com/hooks/yourhook"
user=""
pass=""
plist_path="/Library/Application Support/JAMF/com.yourcompany.computer-info.plist"

# get computer ID and EA ID from our plist
if [[ -f "$plist_path" ]]; then
	computer_id=$(/usr/bin/defaults read "$plist_path" ComputerID)
	ea_id=$(/usr/bin/defaults read "$plist_path" eaID)
else
	echo "**** Plist file does not exist ****"
	exit 99
fi

# get data to upload
lastHour="$(sqlite3 "/Library/Application Support/Apple/AssetCache/Metrics/Metrics.db" "select SUM(ZBYTESFROMCACHETOCLIENT) from ZMETRIC where cast(ZCREATIONDATE as int) > (select strftime('%s','now','-1 hour')-978307200);")"

if [[ "${lastHour}" == "" ]]; then
	cache_stats="0 B"
elif [[ $lastHour -lt 1024 ]]; then
	cache_stats="${lastHour} B"
elif [[ $lastHour -lt 1048576 ]]; then
	stats=$(bc <<< "scale=2; $lastHour/1024")
	cache_stats="$stats KB"
elif [[ $lastHour -lt 1073741824 ]]; then
	stats=$(bc <<< "scale=2; $lastHour/1048576")
	cache_stats="$stats MB"
else
	stats=$(bc <<< "scale=2; $lastHour/1073741824")
	cache_stats="$stats GB"
fi

# build json
json_data='{"computer_id": '$computer_id', "ea_id": '$ea_id', "cache_value": "'$cache_stats'" }'

#send data to jawa
curl -ku $user:$pass -X POST "${webhook_url}" -H "Content-type: application/json" --data "$json_data"
EOF

# fix ownership
/usr/sbin/chown root:wheel "$local_script"

# Set Permissions
/bin/chmod +x "$local_script"

# check if the LaunchDaemon already exists and remove if it does
if [[ -f "$launch_daemon" ]]
then
	# Unload the Launch Daemon and surpress the error
	/bin/launchctl bootout system "$launch_daemon" 2> /dev/null
	rm "$launch_daemon"
fi

# now write out our LaunchDaemon
# be sure to update the path to the script below to match where you are storing the script locally
# You can also update the launch interval if you want this to fire more often than the top of the hour
# or want it to launch on a different interval
tee "$launch_daemon" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$(basename "$ld_path" | sed -e 's/.plist//')</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>/Library/YourCompany/update_cache_stats.sh</string>
	</array>
	<key>StartCalendarInterval</key>
	<dict>
		<key>Minute</key>
		<integer>0</integer>
	</dict>
</dict>
</plist>
EOF

# Set Ownership
/usr/sbin/chown root:wheel "$launch_daemon"

# Set Permissions
/bin/chmod 644 "$launch_daemon"

# Load the Launch Daemon
/bin/launchctl bootstrap system "$launch_daemon"