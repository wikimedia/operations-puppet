# == Class role::analytics_cluster::coordinator::replica
#
class role::analytics_cluster::coordinator::replica {

    system::role { 'analytics_cluster::coordinator::replica':
        description => 'Analytics Cluster backup/replica host running various Hadoop services (Hive, Meta DB, etc..)'
    }

    include profile::analytics::cluster::gitconfig

    include profile::java

    include profile::analytics::cluster::client

    include profile::analytics::refinery_git_config

    # SQL-like queries to data stored in HDFS
    include profile::hive::metastore
    include profile::hive::server

    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::base::production
    include profile::firewall
}
