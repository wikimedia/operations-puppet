# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::dev_cluster {
    include passwords::cassandra # lint:ignore:wmf_styleguide
    include profile::base::firewall
    include profile::base::production
    include profile::rsyslog::udp_localhost_compat

    include profile::cassandra
    include profile::restbase
    include profile::services_proxy::envoy  # service-to-service proxy
    system::role { 'restbase::dev_cluster':
        description => "Restbase-dev (${::realm})",
    }
}
