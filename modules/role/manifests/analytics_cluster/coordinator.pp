# == Class role::analytics_cluster::coordinator
#
# This role includes Hive servers and the Presto coordinator.
#
#
class role::analytics_cluster::coordinator {

    system::role { 'analytics_cluster::coordinator':
        description => 'Analytics Cluster host running various Hadoop services (Hive and Presto)',
    }

    include profile::analytics::cluster::gitconfig

    include profile::java

    include profile::analytics::cluster::client

    # SQL-like queries to data stored in HDFS
    include profile::hive::metastore
    include profile::hive::server

    # (Faster) SQL-like queries to data stored in HDFS and elsewhere
    # coordinator only runs the Presto server as a coordinator process.
    # The actual workers are configured in the presto::server role.
    # This node is marked as a coordinator in hiera.
    include profile::presto::server

    include profile::analytics::refinery
    include profile::analytics::refinery_git_config
    include profile::analytics::cluster::repositories::statistics

    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::base::production
    include profile::firewall
}
