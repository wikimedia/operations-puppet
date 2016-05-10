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
    redis::instance { 6379:
        settings => {
            bind                      => '0.0.0.0',
            appendonly                => true,
            dir                       => '/mnt/redis',
            maxmemory                 => '128Mb',
            requirepass               => 'notsecure',
            auto_aof_rewrite_min_size => '32mb',
        },
    }

    file { '/mnt/redis':
        ensure  => directory,
        mode    => '0775',
        owner   => 'redis',
        group   => 'redis',
        before  => Service['redis-instance-tcp_6379'],
        require => [
            Mount['/mnt'],
            Package['redis-server'],
        ],
    }
}

