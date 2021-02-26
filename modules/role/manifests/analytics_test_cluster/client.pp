# == Class role::analytics_cluster::hadoop::client
# Simple role class that only includes a hadoop client.
#
class role::analytics_test_cluster::client {
    system::role { 'analytics_test_cluster::client':
        description => 'Analytics Hadoop test client',
    }

    include ::profile::java
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::analytics::cluster::client
    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::analytics::cluster::gitconfig

    include ::profile::presto::client

    # Need refinery to test Refine jobs
    include ::profile::analytics::refinery

    include ::profile::swap
    # This class will soon deprecate profile::swap.
    # T224658
    include ::profile::analytics::jupyterhub
}
