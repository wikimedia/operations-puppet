#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Upgrade VRTS Script

. /etc/vrts/install-script-vars

if ! /usr/bin/curl -fL "${DOWNLOAD_URL}/znuny-${1}.tar.gz" -o "/tmp/znuny-${1}.tar.gz"
then
    echo "ERROR: Failed Downloading ${DOWNLOAD_URL}/znuny-${1}.tar.gz"
    exit 1
fi

# Stop before VRTS goes down if the archive is not a valid release
if ! sudo /usr/bin/tar xfz "/tmp/znuny-${1}.tar.gz" -C /opt || [ ! -d "/opt/znuny-${1}/Kernel" ]
then
    echo "ERROR: Failed extracting /tmp/znuny-${1}.tar.gz to /opt/znuny-${1}"
    exit 1
fi

sudo systemctl stop cron
sudo systemctl stop exim4
sudo systemctl stop apache2
sudo systemctl stop vrts-daemon

sudo cp /opt/otrs/Kernel/Config.pm "/opt/znuny-${1}/Kernel"
sudo cp /opt/otrs/var/log/TicketCounter.log "/opt/znuny-${1}/var/log/"

sudo ln -sfn "/opt/znuny-${1}" /opt/otrs
sudo -u root /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete
sudo -u www-data /opt/otrs/bin/otrs.Console.pl Admin::Package::ReinstallAll

sudo systemctl start cron
sudo systemctl start exim4
sudo systemctl start apache2
sudo systemctl start vrts-daemon

# Clean Up
sudo rm -rf "/tmp/znuny-${1}.tar.gz"

sudo puppet agent -t
