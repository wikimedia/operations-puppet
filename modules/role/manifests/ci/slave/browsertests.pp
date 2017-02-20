# == Class role::ci::slave::browsertests
#
# Configure an instance to be used for running Selenium tests against a locally
# installed MediaWiki. Different browsers are included as well as a local
# in-memory X11 server.
class role::ci::slave::browsertests {
    requires_realm('labs')

    system::role { 'role::ci::slave::browsertests':
        description => 'CI Jenkins slave for browser tests',
    }

    include role::ci::slave::labs::common
    include ::contint::mediawiki_selenium
    # Provides phantomjs, firefox and xvfb
    include ::contint::browsers

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
