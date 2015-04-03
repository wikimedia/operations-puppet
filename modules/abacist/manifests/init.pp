# == Class: abacist
#
# Abacist is a simple, Redis-backed web analytics framework.
#
# === Parameters
#
# [*eventlogging_publisher*]
#   EventLogging endpoint. Example: 'tcp://eventlog1001.eqiad.wmnet:8600'.
#
# [*redis_server*]
#   Address of redis server to use as a back-end. Default: 'localhost'.
#
class abacist(
    $eventlogging_publisher,
    $ensure       = 'present',
    $redis_server = 'localhost',
) {
    require_package('python-redis', 'python-zmq')

    group { 'abacist':
        ensure => $ensure,
    }

    user { 'abacist':
        ensure     => $ensure,
        gid        => 'abacist',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    package { 'abacist':
        ensure   => $ensure,
        provider => 'trebuchet',
        notify   => Service['abacist'],
    }

    file { '/etc/init/abacist.conf':
        ensure  => $ensure,
        content => template('abacist/abacist.conf.erb'),
        require => Package['abacist'],
        notify  => Service['abacist'],
    }

    service { 'abacist':
        ensure   => ensure_service($ensure),
        provider => 'upstart',
        require  => User['abacist'],
    }
}
