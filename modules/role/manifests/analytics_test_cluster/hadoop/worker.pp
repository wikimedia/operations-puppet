# == Class role::analytics_test_cluster::hadoop::worker
#
class role::analytics_test_cluster::hadoop::worker {
    include profile::java
    include profile::hadoop::worker
    include profile::hadoop::worker::clients
    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include profile::analytics::cluster::users
    include profile::kerberos::client
    include profile::kerberos::keytabs
    include profile::firewall
    include profile::base::production
}
