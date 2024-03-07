# server running a planet RSS feed aggregator
class role::planet {

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::planet

    # locales are essential for planet
    # if a new language is added check these too
    include ::profile::locales::extended

    include ::profile::tlsproxy::envoy # TLS termination
    include ::profile::prometheus::apache_exporter # T359556

    system::role { 'planet':
        description => 'Planet (rawdog) RSS feed aggregator'
    }
}
