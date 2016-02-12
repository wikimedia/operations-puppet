# == Class role::analytics::hadoop::balancer
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
class role::analytics::hadoop::balancer {
    Class['role::analytics::hadoop::client'] -> Class['role::analytics::hadoop::balancer']

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///files/hadoop/hdfs-balancer',
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
