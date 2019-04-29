# == Class role::analytics_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_cluster::hadoop::client {
    system::role { 'analytics_cluster::hadoop::client':
        description => 'Hadoop client',
    }

    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::hadoop::common
}
