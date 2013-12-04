# application server base class
class redis (
    $port = 6379,
    $dir = '/a/redis',
    $maxmemory = '1GB',
    $maxmemory_policy = 'volatile-lru',
    $maxmemory_samples = 5,
    $persist = 'rdb', # [ rdb, aof, both ]
    $redis_options = {},
    $rename_commands = {},
    $redis_replication = undef,
    $package = 'redis-server',
    $package_version = 'present',
    $servicename = 'redis-server',
    $monitor = true,
    $password = false,
    $auto_aof_rewrite_min_size = '512mb',
) {
    case $::operatingsystem {
        debian, ubuntu: {
        }
        default: {
            fail("Module ${module_name} is not supported on ${::operatingsystem}")
        }
    }

    package { 'redis':
        ensure => $package_version,
        name   => $package,
    }

    file { $dir:
        ensure  => directory,
        owner   => 'redis',
        group   => 'redis',
        mode    => '0755',
        require => Package['redis'],
    }

    file { '/etc/redis/redis.conf':
        content => template('redis/redis.conf.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => Package['redis'],
    }

    service { 'redis':
        ensure  => running,
        name    => $servicename,
        enable  => true,
        require => File['/etc/redis/redis.conf'],
        # subscribe => not doing this deliberately
    }

    if $monitor {
        monitor_service { $servicename: description => "Redis", check_command => "check_tcp!${port}" }
    }
}
