# == Class: role::xenon
#
# Aggregates and graphs stack trace snapshots from MediaWiki
# application servers, showing where time is spent.
#
class role::xenon {
    include ::xenon

    class { '::redis':
        maxmemory         => '1Mb',
        persist           => undef,
        redis_replication => undef,
    }

    Service['redis'] ~> Service['xenon-log']

    apache::site { 'xenon':
        content => template('apache/sites/xenon.erb'),
    }

    ferm::service { 'xenon_http':
        proto => 'tcp',
        port  => '80',
    }
}
