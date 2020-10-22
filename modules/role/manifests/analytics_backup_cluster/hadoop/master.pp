# == Class role::analytics_backup_cluster::hadoop::master
#
class role::analytics_backup_cluster::hadoop::master {
    system::role { 'analytics_backup_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    include ::profile::java
    include ::profile::hadoop::master
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::firewall::master

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::base::firewall
    include ::profile::standard
}
