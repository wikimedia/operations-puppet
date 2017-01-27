#!/bin/bash

function usage {
        echo -e "Usage:\n"
        echo -e "This script replicates an LVM2 block device across the network by taking a remote snapshot\n"
        echo -e "It also saves a snapshot of the local device before replicating from the remote snapshot\n"
        echo -e "block_sync.sh remote_host remote_volume_group remote_logical_volume snapshot_name local_volume_group local_logical_volume local_snapshot_name local_snapshot_size\n"
        echo -e "Example: block_sync.sh 10.64.37.20 misc test snaptest backup test misc-backup 1T\n"
}

if [[ "$#" -ne 5 || "$1" == '-h' ]]; then
    usage
    exit 1
fi

BDSYNC='/usr/bin/bdsync'
SNAPSHOT_MGR='/usr/local/sbin/snapshot-manager'
PV_OPTIONS='-p -t -e -r -a -b'
r_user='root'
r_host=$1
r_vg=$2
r_lv=$3
r_snapshot_name=$4
remotenice=10

l_vg=$5
l_lv=$6
l_snapshot_name=$7
l_snapshot_size=$8
localdev="/dev/${l_vg}/${l_lv}"

blocksize=16384

remote_connect="ssh -i /root/.ssh/id_labstore ${r_user}@${r_host}"

/bin/findmnt --notruncate -P -n -c $localdev
if [ $? -eq 0 ]
then
  echo "Local device is mounted.  Operations may be unsafe."
  exit 1
fi

set -e

(
    /usr/bin/flock --nonblock --exclusive 200

    $remote_connect "/usr/bin/test -e ${BDSYNC}"
    $remote_connect "/usr/bin/test -e ${SNAPSHOT_MGR}"
    /usr/bin/test -e ${SNAPSHOT_MGR}

    $remote_connect "${SNAPSHOT_MGR} create ${r_snapshot_name} ${r_vg}/${r_lv} --force"

    ${SNAPSHOT_MGR} create --size ${l_snapshot_size} ${l_snapshot_name} ${l_vg}/${l_lv} --force

    $BDSYNC --blocksize=$blocksize \
            --remdata "${remote_connect} 'nice -${remotenice} ${BDSYNC} --server'" \
            $localdev "/dev/${r_vg}/${r_snapshot_name}" | \
            pv $PV_OPTIONS | \
            sudo $BDSYNC --patch=$localdev

) 200>/var/lock/${r_vg}_${r_lv}_backup.lock
