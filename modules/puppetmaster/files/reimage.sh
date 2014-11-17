#!/bin/bash
# Helper script for reimaging a server.
# Author: Giuseppe Lavagetto
# Copyright (c) 2014 the Wikimedia Foundation
set -e
set -u
SLEEPTIME=60
FORCE=0

function log  {
    echo "$@"
}

function clean_puppet {
    nodename=${1}
    log "cleaning puppet certificate for ${nodename}"
    puppet cert clean ${nodename}
    # An additional, paranoid check.
    if puppet cert list --all | fgrep -q ${nodename}; then
        log "unable to clean puppet cert, please check manually"
        exit 1
    fi
    log "cleaning puppet facts cache for ${nodename}"
    /usr/local/sbin/puppetstoredconfigclean.rb ${nodename}
}

function clean_salt {
    nodename=${1}
    force_yes=${2}
    log "cleaning salt key cache for ${nodename}"
    # delete the key only if it has been accepted already, we are going to
    # ask confirmation later about unaccepted keys
    if salt-key --list accepted | fgrep -q ${nodename}; then
        if [ ${force_yes} -eq 1 ]; then
            salt-key -y --delete ${nodename}
        else
            salt-key --delete ${nodename}
        fi
    fi
    # salt-key --delete above exits 0 regardless, double check
    if salt-key --list accepted | fgrep -q ${nodename}; then
        log "unable to clean salt key, please check manually"
        exit 1
    fi
}

function sign_puppet {
    nodename=${1}
    force_yes=${2}
    while true; do
        log "Seeking the node cert to sign"
        res=$(puppet cert list | sed -ne "s/\"$nodename\"//p")
        if [ "x${res}" == "x" ]; then
            log "cert not found, sleeping for ${SLEEPTIME}s"
            sleep $SLEEPTIME
            continue
        fi

        if [ ${force_yes} -eq 0 ]; then
            echo "We have found a key for ${nodename} " \
                 "with the following fingerprint:"
            echo "$res"
            echo -n "Can we go on and sign it? (y/N) "
            read choice
            echo
            if [ "x${choice}" != "xy" ]; then
                log "Aborting on user request."
                exit 1
            fi
        fi
        puppet cert -s ${nodename}
        break
    done
}

function sign_salt {
    nodename=${1}
    force_yes=${2}
    while true; do
        log "Seeking the node key to add"
        if ! salt-key --list unaccepted | fgrep -q ${nodename}; then
            log "key not found, sleeping for ${SLEEPTIME}s"
            sleep $SLEEPTIME
            continue
        fi;
        if [ ${force_yes} -eq 1 ]; then
            salt-key -y -a ${nodename}
        else
            salt-key -a ${nodename}
        fi
        break
    done
}

function set_pxe_and_reboot {
    mgmtname=${1}
    if [ -z "$IPMI_PASSWORD" ]; then
	    echo "WARNING: IPMI_PASSWORD not found. Assuming bash, do: "
	    echo "HISTCONTROL=ignoreboth<enter>"
	    echo "<space>export IPMI_PASSWORD='supersecretpass'"
	    echo "WARNING: Continuing without auto rebooting the box"
	    return
    fi
    export IPMI_PASSWORD
    ipmitool -I lanplus -H ${mgmtname} -U root -E chassis bootdev pxe
    ipmitool -I lanplus -H ${mgmtname} -U root -E chassis power cycle

}

function usage {
    echo "Usage: $0 [-y][-s SECONDS] <nodename> <mgmtname>"; exit 1;
}

## Main script

while getopts "ys:" option; do
    case $option in
        y)
            FORCE=1
            ;;
        s)
            SLEEPTIME=${OPTARG}
            ;;
        *)
            usage
            ;;
esac
done
shift $((OPTIND-1))
nodename=$1
mgmtname=$2
test -z ${nodename} && usage
test -z ${mgmtname} && usage
log "Preparing reimaging of node ${nodename}"

clean_puppet $nodename
clean_salt $nodename $FORCE
set_pxe_and_reboot $mgmtname
sign_puppet $nodename $FORCE
sign_salt $nodename $FORCE

log "Node ${nodename} is now signed and both puppet and salt should work."
