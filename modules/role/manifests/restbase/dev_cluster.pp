# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::dev_cluster {
    # Just includes base, no LVS etc.
    include ::role::restbase::base
    include ::profile::services_proxy::envoy  # service-to-service proxy
    system::role { 'restbase::dev_cluster':
        description => "Restbase-dev (${::realm})",
    }
}
