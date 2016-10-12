#!/bin/sh

function usage {
        echo -e "Usage:\n"
        echo -e "This script replicates an LVM2 block device across the network by taking a remote snapshot\n"
        echo -e "block_sync.sh remote_host remote_volume_group remote_logical_volume snapshot_name local_device\n"
        echo -e "Example: block_sync.sh 10.64.37.20 misc test snaptest /dev/backup/test\n"
}

if [[ "$#" -ne 5 || "$1" == '-h' ]]; then
    usage
    exit 1
fi

BDSYNC='/usr/bin/bdsync'
PV_OPTIONS='-p -t -e -r -a -b'
r_user='root'
r_host=$1
r_vg=$2
r_lv=$3
r_snapshot_name=$4
remotenice=10

localdev=$5
blocksize=16384

remote_connect="ssh -i /root/.ssh/id_labstore ${r_user}@${r_host}"

/bin/findmnt --notruncate -P -n -c $localdev
if [ $? -eq 0 ]
then
  echo "Local device is mounted.  Operations may be unsafe."
  exit 1
fi

set -e

$remote_connect "/usr/bin/test -e ${BDSYNC}"
$remote_connect "/root/snapshot-manager.py create ${r_snapshot_name} ${r_vg}/${r_lv} --force"

$BDSYNC --blocksize=$blocksize \
        --remdata "${remote_connect} 'nice -${remotenice} /usr/bin/bdsync --server'" \
        $localdev "/dev/${r_vg}/${r_snapshot_name}" | \
        pv $PV_OPTIONS | \
        sudo $BDSYNC --patch=$localdev
