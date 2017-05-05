#!/bin/bash

# If we are called with --test as the first parameter, this means that
# we change nothing on disk, but indicate with an exit status other
# than 0 that we would have changed anything and with an exit status
# of 0 that this call would have been a no-op.
if [ "x$1" = "x--test" ]; then
  dryrun=1
  shift
else
  dryrun=0
fi

mount="$1"; shift
size="$1"; shift
sopt="-L $size"

# Getting the lvextend version is ugly but we need it because
#  the return codes changed at version 2.02.141 as per
#  https://bugzilla.redhat.com/show_bug.cgi?id=1354396
#
#  $oldlvextend will == 0 if we're running an older version.
lvmversion=`dpkg -s lvm2 | grep Version | cut -d ' ' -f 2`
dpkg --compare-versions $lvmversion lt 2.02.141
oldlvextend=$?

if (/bin/echo "$size"|/bin/grep -q '%'); then
  sopt="-l $size"
fi

if ! mountpoint -q "$mount"; then
  echo "$0: $mount is not a mountpoint" >&2
  exit 1
fi

volume=$(grep "\S* $mount " /proc/mounts | cut -d ' ' -f 1 | tail -n 1)
if [ "x$volume" = "x" -o ! -b "$volume" ]; then
  echo "$0: unable to find device for $mount" >&2
  exit 1
fi
if ! /sbin/lvs "$volume" >/dev/null 2>&1; then
  echo "$0: $mount is not a logical volume" >&2
  exit 1
fi

if /sbin/lvextend -t $sopt "$volume" >/dev/null 2>&1; then
  if [ $dryrun -ne 0 ]; then
    exit 1
  fi
  /sbin/lvextend -r $sopt "$volume"
  exit
else
  lvextend_exitcode=$?

  if [ $oldlvextend -eq 0 ]; then
    if [ $lvextend_exitcode -eq 5 ]; then
      echo "$0: no space left to grow $mount to $size" >&2
      exit 2
    fi
    # This is the only case when --test should succeed: All the tests
    # above have passed and lvextend wouldn't do anything because the
    # partition is already of the requested size.
    if [ $lvextend_exitcode -eq 3 ] && [ $dryrun -ne 0 ]; then
      exit 0
    fi
  else
    if [ $lvextend_exitcode -eq 11 ]; then
      echo "$0: no space left to grow $mount to $size" >&2
      exit 2
    fi
    # Return codes for modern lvextend are unclearly documented.
    #  '5' is supposed to mean 'logical volume not active'
    #  but it's what we get in the correct no-op case
    #  so we'll take it.
    if [ $lvextend_exitcode -eq 5 ] && [ $dryrun -ne 0 ]; then
      exit 0
    fi
  fi

  if [ $dryrun -ne 0 ]; then
    exit 1
  else
    exit 0
  fi
fi
