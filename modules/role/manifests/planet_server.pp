# server running a planet RSS feed aggregator
class role::planet_server {

    include ::standard
    include ::profile::base::firewall
    include ::profile::planet::venus

    system::role { 'planet_server':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
