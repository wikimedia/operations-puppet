#!/bin/bash
# purge Ganglia (T177225)
#
# WIP - untested
/usr/bin/apt-get -y -q remove --purge ganglia-monitor libganglia1
sleep 5
killall -s 9 -u ganglia
rm -rf /usr/lib/ganglia
rm -rf /etc/ganglia
rm -rf /var/lib/ganglia
rm /run/ganglia-monitor.pid
