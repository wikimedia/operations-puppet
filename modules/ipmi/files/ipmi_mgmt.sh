#!/bin/bash

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///modules/ipmi/files/ipmi_mgmt
#####################################################################

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ -z $1 ] # if there is no host, assume they need instructions
then
        echo "Syntax is ipmi_mgmt <host> <commands>"
        echo "Command Listing" 
        echo "Power commands: powercycle, powerdown, powerup, powerstatus, powermonitor"
        echo "Setting one time boot option: bootbios, bootcdrom, bootdisk, bootfloppy, bootpxe"
        echo "Serial Console: console & ~~. to disconnect when done; consoleclose (for unintentional DC that doesn't free the com port)"        
        echo "BMC/LOM specific: bmcinfo, bmcreset."
        echo "Info gathering: fru, id (flash lights on system for local tech ID), log (BMC event log), sdr, sensor, sysinfo"
else

                case $2 in
                        bmcinfo) ipmitool -I lanplus -U root -E -H $1 bmc info;;
                        bmcreset) ipmitool -I lanplus -U root -E -H $1 bmc reset cold;;
                        bootbios) ipmitool -I lanplus -U root -E -H $1 chassis bootdev bios;;
                        bootcdrom) ipmitool -I lanplus -U root -E -H $1 chassis bootdev cdrom;;
                        bootdisk) ipmitool -I lanplus -U root -E -H $1 chassis bootdev disk;;
                        bootfloppy) ipmitool -I lanplus -U root -E -H $1 chassis bootdev floppy;;
                        bootpxe) ipmitool -I lanplus -U root -E -H $1 chassis bootdev pxe;;
                        console) ipmitool -I lanplus -U root -E -H $1 sol activate ;; # serial console 
                        consoleclose) ipmitool -I lanplus -U root -E -H $1 sol deactivate ;; # serial console 
                        fru) ipmitool -I lanplus -U root -E -H $1 fru ;;
                        id) ipmitool -I lanplus -U root -E -H $1 chassis identify ;; # Chassis ID for 15 seconds for onsite techs
                        log) ipmitool -I lanplus -U root -E -H $1 sel list ;; # system BMC event log
                        powercycle) ipmitool -I lanplus -U root -E -H $1 power cycle ;;
                        powerdown) ipmitool -I lanplus -U root -E -H $1 power down ;;
                        powermonitor) ipmitool -I lanplus -U root -E -H $1 delloem powermonitor;;
                        powerstatus) ipmitool -I lanplus -U root -E -H $1 power status ;;
                        powerup) ipmitool -I lanplus -U root -E -H $1 power up ;;
                        sdr) ipmitool -I lanplus -U root -E -H $1 sdr ;;
                        sensor) ipmitool -I lanplus -U root -E -H $1 sensor ;;
                        sysinfo) ipmitool -I lanplus -U root -E -H $1 delloem sysinfo ;;
                        *) echo -e '\E[31mYou have not selected a valid option, please use mgmt with no options to see help text.' ;;
                esac
fi
