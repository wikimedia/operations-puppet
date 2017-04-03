#!/bin/bash
# Common bash functions and variables to use for scripts
PUPPETLOCK=$(puppet agent --configprint agent_catalog_run_lockfile)
PUPPET_DISABLEDLOCK=$(puppet agent --configprint agent_disabled_lockfile)

# Function to test if puppet is running or not
puppet_is_running() {
    # If no lockfile is defined, we can't really tell what's happening.
    # Assume puppet is not running in this case
    test -n $PUPPETLOCK || return 1

    # If the lockfile is not present, puppet is not running
    test -e $PUPPETLOCK || return 1

    # Now let's see if the PID at $PUPPETLOCK is indeed present and running
    PUPPETPID=$(cat $PUPPETLOCK)
    CMDLINE_FILE="/proc/$PUPPETPID/cmdline"
    if [ -f $CMDLINE_FILE ]; then
        # Puppet is indeed running
        grep -q puppet $CMDLINE_FILE && return 0
    fi

    # The lock file is stale, ignore it
    echo "Ignoring stale puppet agent lock for pid ${PUPPETPID}"
    return 1
}

# loop function to wait for puppet to finish its execution
wait_for_puppet() {
    attempts=${1:-30}
    for i in $(seq $attempts); do
        if ! puppet_is_running; then
            return 0
        fi
        sleep 10
    done
    # If puppet is still running at this point, report an error
    return 1
}
