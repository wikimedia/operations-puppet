# == Class role::analytics_cluster::hadoop::balancer
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
class role::analytics_cluster::hadoop::balancer {
    Class['role::analytics_cluster::hadoop::client'] -> Class['role::analytics_cluster::hadoop::balancer']

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///modules/role/analytics_cluster/hadoop/hdfs-balancer',
        mode   => '0754',
        owner  => 'hdfs',
        group  => 'hdfs',
    }

    # logrotate HDFS balancer's log files
    file { '/etc/logrotate.d/hdfs_balancer':
        source => 'puppet:///modules/role/analytics_cluster/hadoop/hadoop_hdfs.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
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
