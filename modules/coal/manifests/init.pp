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
class coal(
    $kafka_brokers,
    $kafka_topic = 'eventlogging_NavigationTiming',
    $kafka_consumer_group = 'coal',
    $whisper_dir = '/var/lib/coal'
  ) {
    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-whisper')
    require_packages('python-confluent-kafka')
    require_packages('python-dateutil')

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
        # uses: $kafka_brokers, $kafka_topic, $kafka_consumer_group, $whisper_dir
        ensure  => present,
        systemd => systemd_template('coal'),
        upstart => upstart_template('coal'),
    }
}
