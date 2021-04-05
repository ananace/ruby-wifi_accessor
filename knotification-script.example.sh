#!/bin/bash

# Ensure everything else gets a chance to complete before the script triggers
sleep 0.1

# Avoid acting on deactivations
tail -n1 /tmp/network-connections.log | grep 'deactivated' &> /dev/null && return 0

# Requires KNotification with the network event "Connection Established" to be
# set up to log to file at /tmp/network-connections.log and run this script
NETWORK=$(tail -n1 /tmp/network-connections.log | sed "s/.*'\(.*\)'.*/\1/")

echo "Connected to \"$NETWORK\" at $(date)" >> /tmp/autologin.log

# Need phantomjs on the path
export PATH="~/.bin:$PATH"
wifi-autologin --login "$NETWORK" &>> /tmp/autologin.log

echo >> /tmp/autologin.log
