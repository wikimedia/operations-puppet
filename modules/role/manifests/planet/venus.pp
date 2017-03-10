# server running a planet RSS feed aggregator
class role::planet_server {

    include standard
    include profile::planet::venus

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
}
