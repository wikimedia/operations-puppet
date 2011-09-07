#!/bin/bash

# Create virtual tapes, label them and initialize.
Conf_name="$1"
Number_tape="$2"
Target_dir="$3"

echo "Received request to create $Number_tape in $Target_dir using $Conf_name configuration"

[[ -s $Target_dir/slots/data ]] && exit 0;

mkdir -p $Target_dir/slots
cd $Target_dir/slots
for ((i=1; $i<=$Number_tape; i++)); do mkdir slot$i; done
ln -s slot1 data
chown -R backup:backup $Target_dir
for ((x=1; $x<=$Number_tape; x++)); do su - backup -c "/usr/sbin/amlabel $Conf_name $Conf_name-$x slot $x" ; done
su - backup -c "/usr/sbin/amtape $Conf_name reset"
