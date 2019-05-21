# server running a planet RSS feed aggregator
class role::planet {

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::planet

    # locales are essential for planet
    # if a new language is added check these too
    include ::profile::locales::extended

    system::role { 'planet':
        description => 'Planet (rawdog) RSS feed aggregator'
    }
}
