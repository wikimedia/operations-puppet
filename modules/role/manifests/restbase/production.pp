# == Class role::restbase::production
#
# Configures the production cluster
class role::restbase::production {
    include passwords::cassandra # lint:ignore:wmf_styleguide
    include profile::base::firewall
    include profile::base::production
    include profile::rsyslog::udp_localhost_compat

    include profile::cassandra
    include profile::restbase
    include profile::lvs::realserver
    include profile::tlsproxy::envoy # TLS termination
    include profile::services_proxy::envoy  # service-to-service proxy
    system::role { 'restbase::production':
        description => 'Restbase (production with Cassandra 3.x)',
    }
}
