# == Class: coal
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
class coal( $endpoint ) {
    require_package('python-flask')
    require_package('python-whisper')
    require_package('python-zmq')

    group { 'coal':
        ensure => present,
    }

    user { 'coal':
        ensure     => present,
        gid        => 'coal',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    uwsgi::app { 'coal':
        settings => {
            uwsgi => {
                'plugins'     => 'python',
                'socket'      => '/run/uwsgi/coal.sock',
                'wsgi-file'   => '/usr/local/bin/coal-web',
                'callable'    => 'app',
                'die-on-term' => true,
                'master'      => true,
                'processes'   => 8,
            },
        },
    }

    file { '/usr/local/bin/coal-web':
        source => 'puppet:///modules/coal/coal-web',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['coal'],
    }

    file { '/usr/local/bin/coal':
        source => 'puppet:///modules/coal/coal',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['coal'],
    }

    file { '/var/lib/coal':
        ensure => directory,
        owner  => 'coal',
        group  => 'coal',
        mode   => '0755',
        before => Service['coal'],
    }

    file { '/etc/init/coal.conf':
        content => template('coal/coal.conf.erb'),
        notify  => Service['coal'],
    }

    service { 'coal':
        ensure   => running,
        provider => upstart,
    }
}
