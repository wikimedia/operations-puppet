# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker {

    include ::standard
    include ::profile::base::firewall
    include ::profile::requesttracker

    system::role { 'requesttracker':
        description => 'RT server'
    }
}
