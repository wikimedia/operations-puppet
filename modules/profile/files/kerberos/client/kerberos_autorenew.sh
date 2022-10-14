#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

# Upon login, check whether a user has a valid kerberos ticket
# If there is a valid ticket, check whether the auto-renewal systemd timer is active
# for this account. If it is not active then create it.
#
function autorenew_is_active {
    /usr/bin/systemctl -q --user is-active krenew-$USER.timer 
}

function create_autorenew_timer {
    echo -e "\nCreating automatic Kerberos ticket renewal service"
    /usr/bin/systemd-run --quiet --user --unit krenew-$USER.timer \
        --on-calendar=daily \
        --description="Kerberos ticket renewal timer for for $USER" \
        --property=StandardOutput=null \
        --property=StandardError=null \
        /usr/bin/sh -c "/usr/bin/klist -s && /usr/bin/krenew -v -L 2> /dev/null"
}

if /usr/bin/klist -s; then
    echo -e '\nYou have a valid Kerberos ticket.'
    autorenew_is_active && echo -e 'Your automatic Kerberos ticket renewal service is also active on this host\n' || create_autorenew_timer
else
    echo -e '\nYou do not have a valid Kerberos ticket in the credential cache, remember to kinit.'
fi
