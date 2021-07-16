#!/bin/bash

# Ensure everything else gets a chance to complete before the script triggers
sleep 0.1

# Need phantomjs on the path
export PATH="~/.bin:$PATH"
if which systemd-cat &> /dev/null; then
    wifi-autologin --login --auto |& systemd-cat -t wifi-autologin
elif which logger &> /dev/null; then
    wifi-autologin --login --auto |& logger -t wifi-autologin
else
    wifi-autologin --login --auto >>& /tmp/autologin.log
fi
