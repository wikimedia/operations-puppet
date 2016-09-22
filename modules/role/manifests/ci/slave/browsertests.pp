class role::ci::slave::browsertests {
    requires_realm('labs')

    system::role { 'role::ci::slave::browsertests':
        description => 'CI Jenkins slave for browser tests',
    }

    include role::ci::slave::labs::common
    include role::zuul::install
    include contint::browsertests

    # For CirrusSearch testing:
    file { '/mnt/elasticsearch':
        ensure => absent,
    }
    file { '/var/lib/elasticsearch':
        ensure  => absent,
    }

    # For CirrusSearch testing:
    $redis_port = 6379

    redis::instance { $redis_port:
        settings => {
            bind                      => '0.0.0.0',
            appendonly                => true,
            dir                       => '/srv/redis',
            maxmemory                 => '128Mb',
            requirepass               => 'notsecure',
            auto_aof_rewrite_min_size => '32mb',
        },
    }
    Mount['/srv'] -> File['/srv/redis'] -> Service["redis-instance-tcp_${redis_port}"]

}
