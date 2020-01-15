#! /bin/bash

if ! lvdisplay | grep . >> /dev/null
then
    echo "$0: lvm is not active on this host; unable to create a volume."
    exit 1
fi

device="$1"
if ! /sbin/parted -s $device mkpart primary $(
    /sbin/parted -s $device print free |
    /bin/grep 'Free Space' |
    /usr/bin/tail -n 1 |
    /bin/sed -e 's/  */ /g' |
    /usr/bin/cut -d ' ' -f 2,3 ); then
  echo "$0: failed to create new partition" >&2
  exit 1
fi

part=$( /sbin/parted -s $device print |
      /bin/grep 'primary' |
      /usr/bin/tail -n 1 |
      /bin/sed -e 's/  */ /g' |
      /bin/sed -e 's/^ *//' |
      /usr/bin/cut -d ' ' -f 1 )
      echo "Last partition [$part]"
if [ "$part" != "" ]; then
  if [ "$part" -gt 2 ]; then
    /sbin/parted -s $device set $part lvm on
    /sbin/pvcreate $device$part
    /sbin/vgcreate vd $device$part
    /sbin/partprobe
    exit 0
  fi
fi
exit 2
