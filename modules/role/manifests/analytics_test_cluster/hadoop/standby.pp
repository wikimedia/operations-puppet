# == Class role::analytics_test_cluster::hadoop::standby
# Include standby NameNode classes
#
# filtertags: labs-project-analytics
class role::analytics_test_cluster::hadoop::standby {
    system::role { 'analytics_test_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }

    include ::profile::hadoop::common
    include ::profile::hadoop::master::standby
    include ::profile::hadoop::firewall::master
    include ::profile::analytics::cluster::users
    include ::profile::hadoop::backup::namenode

    # an-master1002 is usually inactive, and it has a
    # decent amount of disk space.  We use it to
    # store some backups, including fsimage snapshots
    # of Hadoop NameNode metadata, and of the
    # analytics_cluster::database::meta (MySQL analytics-meta) instance.
    # If you move these, make sure /srv/backup has
    # enough space to store backups.
    include ::profile::analytics::database::meta::backup_dest

    include ::profile::kerberos::client

    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::standard

}
