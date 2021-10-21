# = Class: role::puppetmaster::pontoon
#
# Sets up a Pontoon puppetmaster. Meant to work in Cloud VPS only.
# See also https://wikitech.wikimedia.org/wiki/User:Filippo_Giunchedi/Pontoon
#
# filtertags: labs-common
class role::puppetmaster::pontoon {
    system::role { 'puppetmaster::pontoon':
        description => 'Pontoon puppetmaster',
    }

    include profile::base::production
    include profile::base::firewall

    include profile::puppetmaster::pontoon
}
