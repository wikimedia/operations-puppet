# == Class role::analytics_cluster::hadoop::backup::namenode
# Periodically runs hdfs dfsadmin -fetchImage
# and ensures that bacula backs up Hadoop NameNode fsimages,
# in the case we need to recover if both Hadoop NameNodes.
#
class role::analytics_cluster::hadoop::backup::namenode {
    require ::profile::hadoop::client

    include ::role::analytics_cluster::backup

    $destination = '/srv/backup/hadoop/namenode'
    file { [
            '/srv/backup/hadoop',
            $destination
        ]:
        ensure => 'directory',
        owner  => 'hdfs',
        group  => 'analytics-admins',
        mode   => '0750',
    }

    cron { 'hadoop-namenode-backup-fetchimage':
        command => "/usr/bin/hdfs dfsadmin -fetchImage ${destination} > /dev/null 2>&1 ",
        user    => 'hdfs',
        hour    => 0,
        minute  => 0,
    }

    $retention_days = 30
    # Delete files older than $retention_days.
    cron { 'hadoop-namenode-backup-prune':
        command => "/usr/bin/find ${destination} -mtime +${retention_days} -delete > /dev/null 2>&1",
        user    => 'hdfs',
        hour    => 1,
        minute  => 0,
    }

    # Bacula will also back up this directory.
    # See: bacula::director::fileset { 'hadoop-namenode-backup'
    # in profile::backup::director
    class { 'backup::host':
        sets => ['hadoop-namenode-backup', ]
    }
}
