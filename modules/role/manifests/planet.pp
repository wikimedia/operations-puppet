# server running a planet RSS feed aggregator
class role::planet {

    include ::standard
    include ::profile::base::firewall

    class { '::apache': }
    class { '::apache::mod::rewrite': }
    # so we can vary on X-Forwarded-Proto when behind misc-web
    class { '::apache::mod::headers': }

    include ::profile::planet::venus

    system::role { 'planet':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
