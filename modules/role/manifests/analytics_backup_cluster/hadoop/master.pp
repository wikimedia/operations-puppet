# == Class role::analytics_backup_cluster::hadoop::master
#
class role::analytics_backup_cluster::hadoop::master {
    system::role { 'analytics_backup_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    include ::profile::java
    include ::profile::hadoop::master
    # The Analytics team usually keeps master/standby/worker daemons separated
    # for performance reasons. The backup cluster is a special use case since
    # it doesn't really need to sustain a lot of workload (map-reduce jobs,
    # streaming high volumes of data, etc..). The master / standby nodes are
    # regular worker nodes, so adding the worker profile will allow Analytics
    # to have extra HDFS space.
    include ::profile::hadoop::worker
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::firewall::master

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::base::firewall
    include ::profile::standard
}
