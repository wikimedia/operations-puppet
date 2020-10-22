# == Class role::analytics_backup_cluster::hadoop::worker
#
class role::analytics_backup_cluster::hadoop::worker {
    system::role { 'analytics_backup_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    include ::profile::java
    include ::profile::hadoop::worker
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::base::firewall
    include ::profile::standard
}
