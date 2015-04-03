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

    Service['redis-server'] ~> Service['abacist']
}
