#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Install VRTS Script

. /etc/vrts/install-script-vars

pushd /tmp/
curl -L -O $DOWNLOAD_URL/znuny-$1.tar.gz
sudo tar xfz znuny-$1.tar.gz -C /opt
popd

sudo service cron stop
sudo service exim4 stop
sudo service apache2 stop
sudo service vrts-daemon stop

sudo cp /opt/otrs/Kernel/Config.pm /opt/znuny-$1/Kernel
sudo cp /opt/otrs/var/log/TicketCounter.log /opt/znuny-$1/var/log/

sudo ln -sfn /opt/znuny-$1 /opt/otrs
sudo -u root /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete
sudo -u www-data /opt/otrs/bin/otrs.Console.pl Admin::Package::ReinstallAll

sudo service cron start
sudo service exim4 start
sudo service apache2 start
sudo service vrts-daemon start

sudo puppet agent -t