# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker_server {

    include ::standard
    include ::profile::base::firewall
    include ::profile::requesttracker::server

    system::role { 'requesttracker::server':
        description => 'RT server'
    }
}
