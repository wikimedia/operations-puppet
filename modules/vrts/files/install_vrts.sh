#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Install VRTS Script

. /etc/vrts/install-script-vars

if ! /usr/bin/curl -L "${DOWNLOAD_URL}/znuny-${1}.tar.gz"-o "tmp/znuny-${1}.tar.gz"; then
    echo "ERROR: Failed Downloading ${DOWNLOAD_URL}/znuny-${1}.tar.gz"
    exit 1
fi

sudo /usr/bin/tar xfz "/tmp/znuny-${1}.tar.gz" -C /opt

sudo cp /opt/otrs/Kernel/Config.pm "/opt/znuny-${1}/Kernel"
sudo cp /opt/otrs/var/log/TicketCounter.log "/opt/znuny-${1}/var/log/"

sudo ln -sfn "/opt/znuny-${1}" /opt/otrs

sudo -u root /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete
sudo -u www-data /opt/otrs/bin/otrs.Console.pl Admin::Package::ReinstallAll

# Clean Up
sudo rm -rf "/tmp/znuny-${1}.tar.gz"

sudo puppet agent -t
