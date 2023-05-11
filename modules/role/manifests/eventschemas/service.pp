# Class: role::eventschemas::service
#
class role::eventschemas::service {
    system::role { 'eventschemas::service':
        description => 'HTTP Service for event schemas'
    }
    include profile::base::production
    include profile::firewall
    include profile::nginx

    include profile::eventschemas::service
    include profile::tlsproxy::envoy # TLS termination

    include profile::lvs::realserver
}
