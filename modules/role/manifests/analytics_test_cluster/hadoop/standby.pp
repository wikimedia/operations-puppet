# == Class role::analytics_test_cluster::hadoop::standby
# Include standby NameNode classes
#
# filtertags: labs-project-analytics
class role::analytics_test_cluster::hadoop::standby {
    system::role { 'analytics_test_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }

    include ::profile::java
    include ::profile::hadoop::common
    include ::profile::hadoop::master::standby
    include ::profile::hadoop::firewall::master
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::backup::namenode
    include ::profile::hive::client
    include ::profile::hive::site_hdfs
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::base::firewall
    include ::profile::base::linux419
    include ::profile::standard

}
