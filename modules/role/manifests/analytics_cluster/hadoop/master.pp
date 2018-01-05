# == Class role::analytics_cluster::hadoop::master
# Includes cdh::hadoop::master classes
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hadoop::master {
    system::role { 'analytics_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    include ::profile::hadoop::master
    include ::profile::hadoop::users
    include ::profile::hadoop::mysql_password
    include ::profile::hadoop::firewall::master
    include ::profile::hadoop::logstash
    include ::profile::base::firewall
    include standard
}
