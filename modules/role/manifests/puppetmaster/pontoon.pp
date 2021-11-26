# = Class: role::puppetmaster::pontoon
#
# Sets up a Pontoon puppetmaster. Meant to work in Cloud VPS only.
# See also https://wikitech.wikimedia.org/wiki/User:Filippo_Giunchedi/Pontoon
#
class role::puppetmaster::pontoon {
    system::role { 'puppetmaster::pontoon':
        description => 'Pontoon puppetmaster',
    }

    # profile::base is needed here for bootstraps to happen, ideally
    # profile::base::production is used instead
    include profile::base
    include profile::base::firewall

    include profile::puppetmaster::pontoon
}
