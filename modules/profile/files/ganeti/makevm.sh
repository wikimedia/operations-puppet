#!/bin/bash
# interactive script to make a Ganeti VM
#
# Asks the questions needed to follow the steps
# described on:
# https://wikitech.wikimedia.org/wiki/Ganeti#Create_a_VM
#
# Daniel Zahn <dzahn@wikimedia.org>

echo -e "This is an interactive script to make it easier to
create a Ganeti VM.\nPlease see https://wikitech.wikimedia.org/wiki/Ganeti#Create_a_VM for more details.\n"

read -n1 -r -p "$(echo -e 'Are you going to need a public IP? (y/n)\n\b')" PUBLICIP
read -n1 -r -p "$(echo -e '\n\nIf you need a private IP, do you need it to be inside the Analytics VLAN? (y/n)\n\b')" ANALYTICSIP
read -n1 -r -p "$(echo -e '\n\nPlease enter the correct row. (A, B or C - 'gnt-group list' to show)\n\b')" ROW
read -p "$(echo -e '\n\nHow many vCPUs do you need?\n\b')" VCPUS
read -p "$(echo -e '\nHow much RAM do you need? (Gigabytes)\n\b')" MEMORY
read -p "$(echo -e '\nWhat disk size do you need? (Gigabytes)\n\b')" DISKSIZE
read -p "$(echo -e '\nHow do you want to call the instance? (FQDN)\n\b')" FQDN

if [[ $PUBLICIP =~ ^[Yy]$ ]]; then
    LINK="public"
elif [[ $ANALYTICSIP =~ ^[Yy]$ ]]; then
    LINK="analytics"
else
    LINK="private"
fi

ROW=$(echo $ROW | tr [a-z] [A-Z])

create_command="sudo gnt-instance add -t drbd -I hail \
--net 0:link=${LINK} \
--hypervisor-parameters=kvm:boot_order=network \
-o debootstrap+default --no-install -g row_${ROW} \
-B vcpus=${VCPUS},memory=${MEMORY}g \
--disk 0:size=${DISKSIZE}g ${FQDN}"

mac_info_command="sudo gnt-instance list -o nic.mac/0 ${FQDN}"

echo -e "\nBased on your answers this is the full command to create the VM:\n\n${create_command}\n"

read -n1 -r -p "Do you want to run it now? (y/n) " YESNO

if [[ $YESNO =~ ^[Yy]$ ]]; then
    echo -e "\nOk, running.\n"
    eval $create_command
    echo -e "\nTime to add the new instance to DHCP.\nHere's the MAC address:\n"
    eval $mac_info_command
    exit 0
else
    echo -e "\nOk, doing nothing. Bye.\n"
    exit 0
fi

