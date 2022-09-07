#!/bin/bash

# Provision logical volumes and filesystems for Prometheus eqiad/codfw
# Ideally we'd have Puppet manage these resources https://phabricator.wikimedia.org/T163692

set -x

create_fs() {
  local instance=$1
  local size=$2
  local vg=${3:-vg0}

  lv="prometheus-${instance}"
  dev=/dev/$vg/$lv

  if [ ! -e $dev ]; then
    lvcreate --size $size --name $lv $vg
  fi

  if ! blkid --match-token TYPE=ext4 $dev ; then
    mkfs.ext4 -m 0 $dev
  fi
}

mount_fs() {
  local instance=$1
  local vg=${2:-vg0}

  mountpoint=/srv/prometheus/$instance
  lv="prometheus-${instance}"
  dev=/dev/$vg/$lv

  install -d -o prometheus -m 750 $mountpoint

  if ! grep -q "^$dev $mountpoint " /etc/fstab ; then
    echo "$dev $mountpoint  ext4  defaults  0 0" >> /etc/fstab
  fi

  if ! findmnt $mountpoint; then
    mount $mountpoint
  fi
}

provision() {
  local instance=$1
  local size=$2

  create_fs $instance $size
  mount_fs $instance
}

provision analytics 10g
provision ext 10g
provision global 900g
provision k8s 500g
provision k8s-dse 50g
provision k8s-mlserve 50g
provision k8s-staging 50g
provision ops 1.7t
provision services 150g
