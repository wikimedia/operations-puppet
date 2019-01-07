# == Class role::analytics_test_cluster::hadoop::master
# Includes cdh::hadoop::master classes
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_test_cluster::hadoop::master {
    system::role { 'analytics_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    include ::profile::hadoop::master
    include ::profile::hadoop::users
    include ::profile::hadoop::mysql_password
    include ::profile::hadoop::firewall::master
    include ::profile::hadoop::logstash

    # Set up druid cluster deep storage directories.
    include ::profile::analytics::cluster::druid_deep_storage

    include ::profile::base::firewall
    include standard
}
