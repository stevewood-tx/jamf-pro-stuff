#!/bin/bash

#########################################################################################
#
# Copyright (c) 2022, JAMF Software, LLC.  All rights reserved.
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
# You will want to update the script path and script name to be what you would like it to be.
#
# Update these variables: script_path and script_name
# 
# You will want to update the name of the LaunchDaemon, along with the contents of the daemon
# to match the script path and name that you set.
# Update this variable: launchDaemonPath
#
#
#########################################################################################
## VARIABLES

script_path="/private/var/acme/scripts/"
script_name="changemgmtpass.sh"
script="$script_path$script_name"

launchDaemon="/Library/LaunchDaemons/com.acme.changeMgmtPass.plist"

#########################################################################################

# create the script on the local machine
# check for our scripts folder first
if [[  ! -d "$script_path" ]]
then
	/bin/mkdir -p "$script_path"
fi

tee "$script" << EOF
#!/bin/bash

# run randomize policy
/usr/local/jamf/bin/jamf policy -event changeMgmtPassword

# bootout launchd
/bin/launchctl bootout system "$launchDaemon" 2> /dev/null

# remove launchdaemon
rm -f "$launchDaemon"

rm -f "$script"

exit 0
EOF

# fix ownership
/usr/sbin/chown root:wheel "$script"

# Set Permissions
/bin/chmod +x "$script"

# now create LaunchDaemon
# Check to see if the file exists
if [[ -f "$launchDaemon" ]]
then
	# Unload the Launch Daemon and surpress the error
	/bin/launchctl bootout system "$launchDaemon" 2> /dev/null
	rm "$launchDaemon"
fi

tee "$launchDaemon" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$(basename "$launchDaemon" | sed -e 's/.plist//')</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>/private/var/acme/scripts/changemgmtpass.sh</string>
	</array>
	<key>StartInterval</key>
	<integer>120</integer>
</dict>
</plist>
EOF

# Set Ownership
/usr/sbin/chown root:wheel "$launchDaemon"

# Set Permissions
/bin/chmod 644 "$launchDaemon"

# Load the Launch Daemon
/bin/launchctl bootstrap system "$launchDaemon"

exit 0