#!/bin/bash
# Helper script for reimaging a server.
# Author: Giuseppe Lavagetto
# Copyright (c) 2014 the Wikimedia Foundation
set -e
set -u
SLEEPTIME=60
FORCE=0

function log  {
    echo "$@";
}

function clean_puppet {
    nodename=${1}
    log "cleaning puppet certificate for ${nodename}"
    puppet cert clean ${nodename}
    # An additional, paranoid check.
    (puppet cert list --all | fgrep -q ${nodename}; \
        if [ $? eq 0 ]; then log "unable to clean puppet cert, please check manually"; exit 1; fi;)
    log "cleaning puppet facts cache for ${nodename}"
    /usr/local/sbin/puppetstoredconfigclean.rb ${nodename}
}

function clean_salt {
    nodename=${1}
    log "cleaning salt key cache for ${nodename}"
    # This actually exits with 0, no matter what
    salt-key -d ${nodename}
    (salt-key --list accepted | fgrep -q ${nodename}; \
        if [ $? eq 0 ]; then log "unable to clean salt key, please check manually"; exit 1; fi;)
}

function sign_puppet {
    nodename=${1}
    force_yes=${2}
    while 1;
    do
        log "Seeking the node cert to sign"
        res=$(puppet cert list | sed -ne "s/\"$nodename\"//p")
        if [ "x${res}" == "x" ]; then
            log "cert not found, sleeping for 1 minute"
            sleep $SLEEPTIME
            continue
        fi;

        if [ ${force_yes} -eq 0 ]; then
            echo "We have found a key for ${nodename} with the following fingerprint:"
            echo "$res"
            echo "Can we go on and sign it? (y/n)"
            read choice
            echo
            if [ "x${choice}" != "xy" ]; then
                log "Aborting on users request."
                exit 1
            fi;
        fi;
        puppet cert -s ${nodename}
        break
    done
}

function sign_salt {
    nodename=${1}
    while 1;
    do
        log "Seeking the node key to add"
        res=$(salt-key --list unaccepted | sed -ne "s/$nodename//p")
        if [ "x${res}" == "x" ]; then
            log "key not found, sleeping for 1 minute"
            sleep $SLEEPTIME
            continue
        fi;
        salt-key -a ${nodename}
        break
    done

}

function usage {
    echo "Usage: $0 [-y][-s SECONDS] <nodename>"; exit 1;
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
test -z ${nodename} && usage
log "Preparing reimaging of node ${nodename}"

clean_puppet $nodename
clean_salt $nodename
sign_puppet $nodename $FORCE
sign_salt $nodename

log "Node ${nodename} is now signed and both puppet and salt should work."
