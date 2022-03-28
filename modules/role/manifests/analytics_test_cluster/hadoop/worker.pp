# == Class role::analytics_test_cluster::hadoop::worker
#
class role::analytics_test_cluster::hadoop::worker {
    system::role { 'analytics_test_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    include ::profile::java
    include ::profile::hadoop::worker
    include ::profile::hadoop::worker::clients
    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::base::firewall
    include ::profile::base::production
}
