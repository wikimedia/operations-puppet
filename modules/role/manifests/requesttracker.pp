# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker {

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::requesttracker
    include ::profile::tlsproxy::envoy # TLS termination

    system::role { 'requesttracker':
        description => 'RT server'
    }
}
