# == Class role::analytics_cluster::hadoop::standby
# Include standby NameNode classes
#
# filtertags: labs-project-analytics
class role::analytics_cluster::hadoop::standby {
    system::role { 'analytics_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }

    include ::profile::hadoop::client
    include ::profile::hadoop::master::standby
    include ::profile::hadoop::firewall::master
    include ::profile::hadoop::users
    include ::profile::base::firewall
    class { 'standard': }

}
