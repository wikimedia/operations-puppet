# sets up an Etherpad lite server
class role::etherpad {

    system::role { 'etherpad': description => 'Etherpad-lite server' }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::etherpad
    include ::profile::tlsproxy::envoy # TLS termination
}
