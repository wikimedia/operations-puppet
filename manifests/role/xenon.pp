# == Class: role::xenon
#
# Aggregates and graphs stack trace snapshots from MediaWiki
# application servers, showing where time is spent.
#
class role::xenon {
    include ::xenon

    include ::apache::mod::mime
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    class { '::redis':
        maxmemory         => '1Mb',
        persist           => undef,
        redis_replication => undef,
    }

    Service['redis-server'] ~> Service['xenon-log']

    file { '/srv/xenon/theme':
        ensure  => directory,
        source  => 'puppet:///files/xenon/theme',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => 0755,
        recurse => true,
        before  => Apache::Site['xenon'],
    }

    apache::site { 'xenon':
        content => template('apache/sites/xenon.erb'),
    }

    ferm::service { 'xenon_http':
        proto => 'tcp',
        port  => '80',
    }
}
