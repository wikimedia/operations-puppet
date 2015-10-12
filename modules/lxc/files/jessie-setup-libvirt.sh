#!/bin/sh
# Setup a local bridge network for LXC containers
set -e
virsh -c lxc:/// net-define /etc/libvirt/qemu/networks/default.xml
virsh -c lxc:/// net-start default
virsh -c lxc:/// net-autostart default
