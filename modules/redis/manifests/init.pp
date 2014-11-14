# application server base class
class redis (
    $port = 6379,
    $dir = '/srv/redis',
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
    $config_template = 'redis/redis.conf.erb',
    $dbfilename = undef, # filename for rdb. If undef, "$hostname-$port.rdb" is used
    $saves = [ "900 1", "300 100", "60 10000" ], # Save points for rdb
    $stop_writes_on_bgsave_error = false
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
        content => template($config_template),
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

    if $::lsbdistcodename == 'trusty' {
        # Upon a config change, Redis will be restarted
        # if it's listening on localhost only, see RT 7583
        exec {'Restart redis if needed':
            command     => '/usr/sbin/service redis-server restart',
            unless      => '/bin/netstat -lp | /bin/grep redis | /usr/bin/awk \'{print $4}\' | /bin/grep -v localhost 2> /dev/null',
            subscribe   => File['/etc/redis/redis.conf'],
            refreshonly => true,
        }
    }

    if $monitor {
        monitoring::service { $servicename: description => "Redis", check_command => "check_tcp!${port}" }
    }
}
