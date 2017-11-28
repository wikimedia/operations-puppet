# server running a planet RSS feed aggregator
class role::planet {

    include ::standard
    include ::profile::base::firewall
    include ::profile::planet::venus

    system::role { 'planet':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
