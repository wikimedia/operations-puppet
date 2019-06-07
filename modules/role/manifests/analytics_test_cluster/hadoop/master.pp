# == Class role::analytics_test_cluster::hadoop::master
# Includes cdh::hadoop::master classes
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_test_cluster::hadoop::master {
    system::role { 'analytics_test_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    include ::profile::hadoop::master
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::firewall::master

    # This needs to be included only on single Hadoop node.
    include ::profile::analytics::cluster::secrets

    # Set up druid cluster deep storage directories.
    include ::profile::analytics::cluster::druid_deep_storage

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::standard
}
