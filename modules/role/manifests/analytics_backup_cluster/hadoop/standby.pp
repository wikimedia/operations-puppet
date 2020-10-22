# == Class role::analytics_backup_cluster::hadoop::standby
#
class role::analytics_backup_cluster::hadoop::standby {
    system::role { 'analytics_backup_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }

    include ::profile::java
    include ::profile::hadoop::common
    include ::profile::hadoop::master::standby
    include ::profile::hadoop::firewall::master
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::backup::namenode
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::base::firewall
    include ::profile::standard

}
