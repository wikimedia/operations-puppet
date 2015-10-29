#!/bin/bash

# This captures aggregated clienthello data for the commandline-specified
# number of seconds on our cache machines in a format suitable for later input
# to "cipher_sim.py".  It should buffer and process the output fairly
# efficiently, not consuming huge memory or CPU time and outputting
# ~100K-ish of aggregate stdout data you'll want to redirect to an output file.
#
# Assumes installed jessie versions of "tcpdump", "tshark", and "perl".

set -e
set -o pipefail

if [ $# != 1 ]; then
    echo "You must supply a number of seconds to capture as the only argument" 1>&2
    exit 99
fi

SECS=$1
case $SECS in
    ''|*[!0-9]*)
        echo "Seconds argument $SECS is not an integer" 1>&2
        exit 98
        ;;
esac

PUSER=nobody
BPF='dst port 443 and (tcp[((tcp[12:1] & 0xf0) >> 2)+5:1] = 0x01) and (tcp[((tcp[12:1] & 0xf0) >> 2):1] = 0x16)'

# "Pay no attention to that man behind the curtain" ...
/usr/sbin/tcpdump -Z $PUSER -npi eth0 --direction=in -s 0 -W 1 -G $SECS -w - "$BPF" 2>/dev/null \
  | su $PUSER -s /bin/sh -c "/usr/bin/tshark -n -Tfields -e ssl.handshake.ciphersuite -r -" 2>/dev/null \
  | /usr/bin/perl -Minteger -lne '$x{join(",",sort(split(",",$_)))}++;END{while(($k,$v)=each %x){print"$v;$k"}}'
