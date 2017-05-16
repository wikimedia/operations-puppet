#!/bin/sh
#
# usage: retrieve-cert.sh remote.host.name [port]
# From http://www.chrissearle.org/node/260
# $Id: retrieve-cert.sh 331 2010-11-19 22:47:10Z bpd $

REMHOST=$1
REMPORT=${2:-443}
echo |\
openssl s_client -connect ${REMHOST}:${REMPORT} 2>&1 |\
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
