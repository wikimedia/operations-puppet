#!/bin/sh

#PV_OPTIONS='-p -t -e -r -a -b'
PV_OPTIONS='-q'

remotehost=$1

remotedev=$2

localdev=$3

remotenice=10

blocksize=16384

/bin/findmnt --notruncate -P -n -c $localdev
if [ $? -eq 0 ]
then
  echo "Local device is mounted.  Operations may be unsafe."
  exit 1
fi

/usr/bin/bdsync --blocksize=$blocksize \
    --remdata "ssh -i /root/.ssh/id_labstore root@$remotehost 'nice -${remotenice} /usr/bin/bdsync --server'" \
    $localdev \
    $remotedev | pv $PV_OPTIONS | sudo /usr/bin/bdsync --patch=$localdev
