# == Class role::analytics_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_cluster::hadoop::client {
    system::role { 'analytics_cluster::hadoop::client':
        description => 'Hadoop client',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::java
    include ::profile::hadoop::common

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
