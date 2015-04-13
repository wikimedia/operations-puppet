# == Class: brrd
#
# This Puppet module provisions a set of client-side performance
# monitoring scripts for Wikimedia sites.
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   For example, 'tcp://eventlogging.eqiad.wmnet:8600'.
#
class brrd( $endpoint ) {
    require_package('python-cliff', 'python-rrdtool')

    package { 'brrd':
        provider => 'trebuchet',
        notify   => Service['brrd'],
    }

    group { 'brrd':
        ensure => present,
    }

    user { 'brrd':
        ensure     => present,
        gid        => 'brrd',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { [ '/var/lib/brrd', '/var/log/brrd' ]:
        ensure => directory,
        owner  => 'brrd',
        group  => 'brrd',
        mode   => '0755',
        before => Service['brrd'],
    }

    file { '/etc/init/brrd.conf':
        content => template('webperf/brrd.conf.erb'),
        notify  => Service['brrd'],
    }

    service { 'brrd':
        ensure   => running,
        provider => upstart,
    }
}
