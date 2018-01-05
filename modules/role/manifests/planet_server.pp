# server running a planet RSS feed aggregator
class role::planet_server {

    include ::standard
    include ::profile::base::firewall
    include ::profile::planet::venus
    # locales are essential for planet
    # if a new language is added check these too
    include ::profile::locales::extended

    class { '::apache': }
    class { '::apache::mod::rewrite': }
    # so we can vary on X-Forwarded-Proto when behind misc-web
    class { '::apache::mod::headers': }

    system::role { 'planet_server':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
