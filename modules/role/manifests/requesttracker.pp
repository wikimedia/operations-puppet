# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker {

    system::role { 'requesttracker':
        description => 'RT server'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::requesttracker
    include ::profile::tlsproxy::envoy # TLS termination

}
