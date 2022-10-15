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
### Variables
script_path="/private/var/acme/scripts/"
script_name="changemgmtpass.sh"
script="$script_path$script_name"

launchDaemon="/Library/LaunchDaemons/com.acme.changeMgmtPass.plist"

# Run the management randomization policy
/usr/local/jamf/bin/jamf policy -event changeMgmtPassword

# now bootout the launch daemon we loadead and delete
# bootout launchd
/bin/launchctl bootout system "$launchDaemon" 2> /dev/null

# remove launchdaemon
rm -f "$launchDaemon"

# remove the script
rm "$script"

exit 0