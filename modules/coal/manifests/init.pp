# == Class: coal
#
# Captures NavigationTiming events from Kafka and writes
# a subset of metric directly to Whisper files.
#
# This complements webperf::navtiming, which uses StatsD and writes
# to Graphite's default backend via carbon.  StatsD produces derived metrics,
# like 'p99' and 'sample_rate'. Graphite aggregates Carbon's Whisper files
# at varying resolutions as data gets older.
#
# Coal, on the other hand, simply retains data for 1 year at a constant
# resolution of 1-minute.
#
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   For example, 'tcp://eventlogging.eqiad.wmnet:8600'.
#
# [*kafka_brokers*]
#   String of comma separated Kafka bootstrap brokers.
#
class coal( $endpoint ) {
    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-whisper')
    require_package('python-kafka')

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
        service_settings => '--die-on-term',
        settings         => {
            uwsgi => {
                'plugins'   => 'python',
                'socket'    => '/run/uwsgi/coal.sock',
                'wsgi-file' => '/usr/local/bin/coal-web',
                'callable'  => 'app',
                'master'    => true,
                'processes' => 8,
            },
        },
    }

    file { '/usr/local/bin/coal-web':
        source => 'puppet:///modules/coal/coal-web',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['uwsgi-coal'],
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

    base::service_unit { 'coal':
        ensure  => present,
        systemd => systemd_template('coal'),
        upstart => upstart_template('coal'),
    }
}
