# == Class role::analytic_cluster::client
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class role::analytics_cluster::client {
    system::role { 'analytics_cluster::client':
        description => 'Client node for interacting with the Analytics Cluster',
    }

    include ::profile::analytics::cluster::client
}