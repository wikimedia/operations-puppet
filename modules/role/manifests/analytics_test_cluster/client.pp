# == Class role::analytics_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_test_cluster::client {
    system::role { 'analytics_test_cluster::client':
        description => 'Analytics Hadoop test cluster\'s client',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::analytics::cluster::client
    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
