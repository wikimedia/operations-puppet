#!/bin/bash

name="$1"; shift
size="$1"; shift
fstype="$1"; shift
sopt=("-L" "$size")

if (echo "$size"|grep '%'); then
  sopt=("-l" "$size")
fi

# `--wipesignatures n` disables the check looking up for an existing file
# system when creating the logical volume. That allows recreating a volume from
# Puppet when one existed previously and got manually removed.
if /sbin/lvcreate --wipesignatures n "${sopt[@]}" -n "$name" vd; then
  makefs="/sbin/mkfs -t $fstype"
  if [ "$fstype" = "swap" ]; then
    makefs="/sbin/mkswap"
  fi
  if ! $makefs "$@" "/dev/vd/$name"; then
    /sbin/lvremove "vd/$name"
    exit 1
  else
    exit 0
  fi
fi
exit 1
