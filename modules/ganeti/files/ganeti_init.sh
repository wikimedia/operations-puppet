#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# WARNING: Read and understand this before running it!!!!

# This is a small shell script containing a set of commands that can not be
# puppetized easily and are required to be run on a ganeti host before it's
# ready to join the cluster

ENI=${ENI:-/etc/network/interfaces}

declare -A PUBLIC_VLANS
declare -A PRIVATE_VLANS
declare -A ANALYTICS_VLANS

PUBLIC_VLANS=(
	["a-eqiad"]=1001
	["b-eqiad"]=1002
	["c-eqiad"]=1003
	["d-eqiad"]=1004
	["a-codfw"]=2001
	["b-codfw"]=2002
	["c-codfw"]=2003
	["d-codfw"]=2004
)

PRIVATE_VLANS=(
	["a-eqiad"]=1017
	["b-eqiad"]=1018
	["c-eqiad"]=1019
	["d-eqiad"]=1020
	["a-codfw"]=2017
	["b-codfw"]=2018
	["c-codfw"]=2019
	["d-codfw"]=2020
)

ANALYTICS_VLANS=(
	["a-eqiad"]=1030
	["b-eqiad"]=1021
	["c-eqiad"]=1022
	["d-eqiad"]=1023
)

interface_primary=`sudo facter -p interface_primary`
lldp_neighbor=`sudo facter -p lldp.${interface_primary}.neighbor`
private_iface=${lldp_neighbor#asw-}
public_iface=${lldp_neighbor#asw-}
private_iface=${private_iface#asw2-}
public_iface=${public_iface#asw2-}

public_vlan="${PUBLIC_VLANS[$public_iface]}"
private_vlan="${PRIVATE_VLANS[$private_iface]}"
analytics_vlan="${ANALYTICS_VLANS[$private_iface]}"

function create_lvm {
	device=$1
	# Undo the ugly trick were /dev/md2 is a swap on purpose to trick partman
	swapoff $device || true
	/sbin/pvcreate $device
	/sbin/vgcreate ganeti $device
}

function create_eni {
	sed -i \
	-e "/auto lo/c auto lo private ${interface_primary}.${public_vlan} ${interface_primary}.${analytics_vlan} public analytics" \
	-e "s/iface ${interface_primary} inet static/iface private inet static/" \
	-e "/dns-search/a\ \tbridge_ports\t${interface_primary}\n\tbridge_stp\toff\n\tbridge_maxwait\t0\n\tbridge_fd\t0\n" \
	-e "/pre-up/d" \
	-e "s/up ip addr add \(.*\) dev ${interface_primary}/up ip addr add \1 dev private/" \
	${ENI}

	cat << EOF >> ${ENI}
iface ${interface_primary}.${public_vlan} inet manual
iface ${interface_primary}.${analytics_vlan} inet manual

iface public inet manual
	bridge_ports	${interface_primary}.${public_vlan}
	bridge_stp 	off
	bridge_maxwait	0
	bridge_fd	0

iface analytics inet manual
	bridge_ports	${interface_primary}.${analytics_vlan}
	bridge_stp 	off
	bridge_maxwait	0
	bridge_fd	0
EOF
}

function usage {
	cat << EOF
WARNING: Running this script is dangerous and has a number of built-in
assumptions. Most notably:
* the VLAN information may be out of date or incomplete
* It WILL mangle /etc/network/interfaces without asking for confirmation
* It WILL generate a broken /etc/network/interfaces anywhere else but eqiad due to analytics. Make
sure to remove that manually before rebooting
* It WILL mark the device passed as first argument an an LVM physical volume and
create a volumge group on top of it, overwriting everything in it.

Takes 1 argument: device to treat as an LVM volume

EOF
}

if [ $# -eq 0 ]
then
	usage
else
	create_eni
	create_lvm $1
fi
