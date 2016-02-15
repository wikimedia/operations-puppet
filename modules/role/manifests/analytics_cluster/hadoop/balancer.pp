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

    cron { 'hdfs-balancer':
        command => '/usr/local/bin/hdfs-balancer >> /var/log/hadoop-hdfs/balancer.log 2>&1',
        user    => 'hdfs',
        # Every day at 6am UTC.
        minute  => 0,
        hour    => 6,
        require => File['/usr/local/bin/hdfs-balancer'],
    }
}
