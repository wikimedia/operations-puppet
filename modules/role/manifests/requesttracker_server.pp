# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker_server {

    include ::standard
    include ::profile::requesttracker::server

    system::role { 'role::requesttracker::server':
        description => 'RT server'
    }
}
