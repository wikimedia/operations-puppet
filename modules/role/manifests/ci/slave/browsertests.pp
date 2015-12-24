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
        ensure => 'directory',
    }
    file { '/var/lib/elasticsearch':
        ensure  => 'link',
        require => File['/mnt/elasticsearch'],
        target  => '/mnt/elasticsearch',
        force   => true,
    }
    class { '::elasticsearch':
        cluster_name => 'jenkins',
        heap_memory  => '1G', #We have small data in test
        require      => File['/var/lib/elasticsearch'],
        # We don't have reliable multicast in labs but we don't mind because we
        # only use a single instance

        # Right now we're not testing with any of the plugins we plan to install
        # later.  We'll cross that bridge when we come to it.
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
}

