# == Class role::analytics_cluster::launcher
#
class role::analytics_cluster::launcher {

    system::role { 'analytics_cluster::launcher':
        description => 'Analytics Cluster host running periodical jobs (Hadoop, Report Updater, etc..)'
    }

    include ::profile::analytics::cluster::client

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users

    include ::profile::hive::site_hdfs

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::standard
    include ::profile::base::firewall
}