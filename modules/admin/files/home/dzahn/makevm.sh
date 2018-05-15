#!/bin/bash
# make a Ganeti VM
# https://wikitech.wikimedia.org/wiki/Ganeti#Create_a_VM

echo -e "This is an interactive script to make it easier to
create a Ganeti VM.\nPlease see https://wikitech.wikimedia.org/wiki/Ganeti#Create_a_VM for more details.\n"

read -n1 -r -p "$(echo -e 'Are you going to need a public IP? (y/n)\n\b')" PRIVATEIP
read -n1 -r -p "$(echo -e '\n\nPlease enter the correct row. (A, B or C - 'gnt-group list' to show)\n\b')" ROW
read -p "$(echo -e '\n\nHow many vCPUs do you need?\n\b')" VCPUS
read -p "$(echo -e '\nHow much RAM do you need? (Gigabytes)\n\b')" MEMORY
read -p "$(echo -e '\nWhat disk size do you need? (Gigabytes)\n\b')" DISKSIZE
read -p "$(echo -e '\nHow do you want to call the instance? (FQDN)\n\b')" FQDN

if [[ $PRIVATEIP =~ ^[Yy]$ ]]; then
    LINK="public"
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

echo -e "\nBased on your answers this is the full command to create the VM:\n\n${create_command}\n"

read -n1 -r -p "Do you want to run it now? (y/n) " YESNO

if [[ $YESNO =~ ^[Yy]$ ]]; then
    echo -e "\nok, running\n"
    eval $create_command
    exit 0
else
    echo -e "\nok, doing nothing. bye\n"
    exit 0
fi

