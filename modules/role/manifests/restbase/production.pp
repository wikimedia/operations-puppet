# == Class role::restbase::production
#
# Configures the production cluster
class role::restbase::production {
    include ::role::restbase::base
    include ::profile::lvs::realserver
    include ::profile::tlsproxy::envoy # TLS termination
    include ::profile::services_proxy::envoy  # service-to-service proxy
    system::role { 'restbase::production':
        description => 'Restbase (production with Cassandra 3.x)',
    }
}
