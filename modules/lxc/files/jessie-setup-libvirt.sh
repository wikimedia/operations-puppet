#!/usr/bin/env bash
set -e
virsh -c lxc:/// net-define /etc/libvirt/qemu/networks/default.xml
virsh -c lxc:/// net-start default
virsh -c lxc:/// net-autostart default
