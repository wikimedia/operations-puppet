class redis::legacy (
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
    $saves = [ '900 1', '300 100', '60 10000' ], # Save points for rdb
    $stop_writes_on_bgsave_error = false,
    $expose = true,
) {
    include ::redis

    file { '/etc/redis/redis.conf':
        content => template('redis/redis.conf.erb'),
        owner   => 'redis',
        group   => 'root',
        mode    => '0440',
        require => Package['redis-server'],
    }

    service { 'redis-server':
        ensure  => running,
        enable  => true,
        require => File['/etc/redis/redis.conf'],
    }

    # member() doesn't like it when $persist is false
    if $persist and member(['rdb', 'aof', 'both'], $persist) {
        # Background save may fail under low memory condition unless
        # vm.overcommit_memory is 1. This is enabled only if persistance
        # is enabled
        sysctl::parameters { 'vm.overcommit_memory':
            values => { 'vm.overcommit_memory' => 1, },
        }
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

    if $password {
        $collector_settings = { auth => $password }
    } else {
        $collector_settings = {}
    }

    ::diamond::collector { 'Redis':
        settings => $collector_settings,
    }
}
