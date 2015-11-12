# == Class: role::abacist
#
# Abacist is a simple, redis-backed web analytics framework.
#
class role::abacist {
    class { '::abacist':
        ensure                 => absent,
        eventlogging_publisher => 'tcp://eventlog1001.eqiad.wmnet:8600',
    }
}
