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
    $monitor = true,
    $password = false,
    $auto_aof_rewrite_min_size = '512mb',
    $dbfilename = undef, # filename for rdb. If undef, "$hostname-$port.rdb" is used
    $saves = [ "900 1", "300 100", "60 10000" ], # Save points for rdb
    $stop_writes_on_bgsave_error = false
) {
    package { 'redis-server':
        ensure => present,
    }

    file { $dir:
        ensure  => directory,
        owner   => 'redis',
        group   => 'redis',
        mode    => '0755',
        require => Package['redis-server'],
    }

    file { '/etc/redis/redis.conf':
        content => template('redis/redis.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['redis-server'],
    }

    service { 'redis-server':
        ensure  => running,
        enable  => true,
        require => File['/etc/redis/redis.conf'],
    }

    if os_version('ubuntu >= trusty || debian >= jessie') {
        # Upon a config change, Redis will be restarted
        # if it's listening on localhost only, see T83956
        exec { 'Restart redis if needed':
            command     => '/usr/sbin/service redis-server restart',
            unless      => '/bin/netstat -lp | /bin/grep redis | /usr/bin/awk \'{print $4}\' | /bin/grep -v localhost 2> /dev/null',
            subscribe   => File['/etc/redis/redis.conf'],
            refreshonly => true,
        }
    }

    if $monitor {
        monitoring::service { 'redis-server':
            description   => 'Redis',
            check_command => "check_tcp!${port}",
        }
    }
}
