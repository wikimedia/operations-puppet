# == Class: role::abacist
#
# Abacist is a simple, redis-backed web analytics framework.
#
class role::abacist {
    class { '::redis':
        maxmemory => '1Gb',
        before    => Class['::abacist'],
    }

    class { '::abacist':
        eventlogging_publisher => 'tcp://eventlog1001.eqiad.wmnet:8600',
    }

    # The redis server is only accessed from localhost (and monitoring), so
    # no further ferm rules are needed
    Service['redis-server'] ~> Service['abacist']
}
