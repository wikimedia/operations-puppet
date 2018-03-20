# == Class profile::hadoop::balancer
#
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
#
class profile::hadoop::balancer {
    require ::profile::hadoop::common

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///modules/profile/hadoop/hdfs-balancer',
        mode   => '0754',
        owner  => 'hdfs',
        group  => 'hdfs',
    }

    # logrotate HDFS balancer's log files
    logrotate::conf { 'hdfs_balancer':
        ensure => 'present',
        source => 'puppet:///modules/profile/hadoop/hadoop_balancer.logrotate',
    }

    cron { 'hdfs-balancer':
        command => '/usr/local/bin/hdfs-balancer >> /var/log/hadoop-hdfs/balancer.log 2>&1',
        user    => 'hdfs',
        # Every day at 6am UTC.
        minute  => 0,
        hour    => 6,
        require => File['/usr/local/bin/hdfs-balancer'],
    }
}
