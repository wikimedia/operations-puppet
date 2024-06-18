# == Class role::analytics_test_cluster::hadoop::standby
# Include standby NameNode classes
#
class role::analytics_test_cluster::hadoop::standby {
    include profile::java
    include profile::hadoop::common
    include profile::hadoop::master::standby
    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include profile::analytics::cluster::users
    include profile::hadoop::firewall::master
    include profile::hadoop::backup::namenode
    include profile::analytics::cluster::hadoop::yarn_capacity_scheduler
    include profile::hive::client
    include profile::hive::site_hdfs
    include profile::kerberos::client
    include profile::kerberos::keytabs
    include profile::firewall
    include profile::base::production
}
