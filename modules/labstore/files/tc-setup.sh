#!/bin/bash

# this script applies traffic shaping using tc.
# it is intended to target NFS traffic, but since
# the NFS hosts do not offer other services it is
# applied based on IP.

# intended as idempotent

# tc -s qdisc show
# http://lartc.org/manpages/tc.txt

modules='act_mirr ifb'
nfs_write='7000kbps'
nfs_read='9500kbps'
eth0_egress='30000kbps'

function ensure_mod {
    value=$(/sbin/lsmod | /bin/grep $1)
    retcode=$?
    if [ $retcode != 0 ]
    then
        echo "$1 is not loaded"
        exit 1
    fi
}

for m in $modules; do
    ensure_mod $m
done

TC=$(which tc)

# clear out old config
$TC qdisc del dev eth0 root

$TC qdisc add dev eth0 root handle 1: htb default 100

$TC class add dev eth0 parent 1: classid 1:1 htb rate $nfs_write

$TC class add dev eth0 parent 1: classid 1:2 htb rate $nfs_write

$TC class add dev eth0 parent 1: classid 1:3 htb rate $nfs_write

$TC class add dev eth0 parent 1: classid 1:100 htb rate $eth0_egress

$TC filter add dev eth0 parent 1: protocol ip prio 0 u32 \
	  match ip dst 10.64.37.6 flowid 1:1

$TC filter add dev eth0 parent 1: protocol ip prio 0 u32 \
	  match ip dst 10.64.37.7 flowid 1:2

$TC filter add dev eth0 parent 1: protocol ip prio 0 u32 \
	  match ip dst 10.64.37.10 flowid 1:3

#-------------------------------------

# clear out config
$TC qdisc del dev eth0 handle ffff: ingress
$TC qdisc del dev ifb0 root

# Create ingress on external interface
$TC qdisc add dev eth0 handle ffff: ingress

# this link has to come up for ingress shaping
/sbin/ip link set dev ifb0 up
retcode=$?
if [ $retcode != 0 ]
then
    echo "ifb0 is not coming up"
    $TC qdisc del dev eth0 handle ffff: ingress
    $TC qdisc del dev ifb0 root
    exit 1
fi

# pass engress traffic through ifb0
$TC filter add dev eth0 parent ffff: protocol all u32 \
    match u32 0 0 action mirred egress redirect dev ifb0

$TC qdisc add dev ifb0 root handle 1: htb

$TC class add dev ifb0 parent 1: classid 1:1 htb rate $nfs_read

$TC class add dev ifb0 parent 1: classid 1:2 htb rate $nfs_read

$TC class add dev ifb0 parent 1: classid 1:3 htb rate $nfs_read

$TC filter add dev ifb0 parent 1: protocol ip prio 0 u32 \
	  match ip src 10.64.37.6 flowid 1:1

$TC filter add dev ifb0 parent 1: protocol ip prio 0 u32 \
	  match ip src 10.64.37.7 flowid 1:2

$TC filter add dev ifb0 parent 1: protocol ip prio 0 u32 \
	  match ip src 10.64.37.10 flowid 1:3
