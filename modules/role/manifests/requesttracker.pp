# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker {

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::requesttracker

    system::role { 'requesttracker':
        description => 'RT server'
    }
}
