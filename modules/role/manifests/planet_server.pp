# server running a planet RSS feed aggregator
class role::planet_server {

    include standard
    include profile::planet::venus

    system::role { 'role::planet_server':
        description => 'Planet (venus) weblog aggregator'
    }

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
}
