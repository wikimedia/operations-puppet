# == Class: webperf::coal
#
# Store a basic set of Navigation Timing metrics in Whisper files.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   For example, 'tcp://eventlogging.eqiad.wmnet:8600'.
#
class webperf::coal( $endpoint ) {
    include ::webperf

    require_package('python-numpy')
    require_package('python-whisper')
    require_package('python-zmq')

    file { '/usr/local/bin/coal':
        source => 'puppet:///modules/webperf/coal',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['coal'],
    }

    file { '/var/lib/coal':
        ensure => directory,
        owner  => 'webperf',
        group  => 'webperf',
        mode   => '0755',
        before => Service['coal'],
    }

    file { '/etc/init/coal.conf':
        content => template('webperf/coal.conf.erb'),
        notify  => Service['coal'],
    }

    service { 'coal':
        ensure   => running,
        provider => upstart,
    }
}
