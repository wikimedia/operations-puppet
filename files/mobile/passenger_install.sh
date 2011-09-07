#!/bin/bash
#####################################################################
### THIS FILE IS MANAGED BY PUPPET 
### puppet:///files/mobile/passenger_install.sh
#####################################################################
echo "installing new passenger version..."
[ -d /srv/mobile/current ] && cd /srv/mobile/current && /var/lib/gems/1.9.1/bin/bundle install
/var/lib/gems/1.9.1/bin/passenger-install-apache2-module --auto
/var/lib/gems/1.9.1/bin/passenger-install-apache2-module --snippet > /etc/apache2/mods-enabled/passenger.load
sed -i '$d' /etc/apache2/mods-enabled/passenger.load
grep -q PassengerRuby /etc/apache2/mods-enabled/passenger.load || echo "PassengerRuby /usr/bin/ruby1.9.1" >> /etc/apache2/mods-enabled/passenger.load
apache2ctl restart
echo ""
echo "Completed."
