#!/bin/bash

# Disable when non-interactive.
if ! tty -s; then
    return
fi

# Check if user wants to display tips.
if [ -f ~/.suppresstips ]; then
    return
fi

# Check if there is a tip DB.
if [ ! -f /data/project/.system/tips ]; then
    return
fi

# Don't display tips for root and tool accounts.
if [ $UID -eq 0 ] || [ "${USER:0:6}" = "tools." ]; then
    return
fi

# Check shell level.
if [ "$SHLVL" -gt 1 ]; then
    return
fi

# If user is sysadmin print the sysadmin motd instead.
if groups | fgrep -qw tools.admin; then
    if [ -f /etc/motd.sysadmin ]; then
        echo
        echo
        cat /etc/motd.sysadmin
    fi

    # We don't want to show tips to sysadmins.
    return
fi

echo -e "\n\033[0;1;4mDid you know\033[0m that `shuf -n 1 /data/project/.system/tips`\n"
