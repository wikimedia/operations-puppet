# server running a planet RSS feed aggregator
class role::planet_server {

    include ::standard
    include ::profile::base::firewall

    class { '::apache': }
    class { '::apache::mod::rewrite': }
    # so we can vary on X-Forwarded-Proto when behind misc-web
    class { '::apache::mod::headers': }
    class { '::apache::mod::http2': }

    include ::profile::planet::venus

    system::role { 'planet_server':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
