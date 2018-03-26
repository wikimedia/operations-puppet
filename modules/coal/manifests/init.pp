# == Class: coal
#
# Store a basic set of Navigation Timing metrics in Whisper files.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*kafka_brokers*]
#   List of kafka brokers to use for bootstrapping
#
# [*kafka_consumer_group*]
#   Name of the consumer group to use for Kafka
#
# [*el_schemas*]
#   Event Logging schemas that should be read from Kafka.  Topic names are
#   derived from these values (eventlogging_$schema)
#
# [*whisper_dir*]
#   Where to write the whisper files that are created
#
# [*log_dir*]
#   Directory where coal's logs should be written by rsyslog
#
class coal(
    $kafka_brokers,
    $kafka_consumer_group = 'coal',
    $el_schemas = ['NavigationTiming', 'SaveTiming'],
    $whisper_dir = '/var/lib/coal',
    $log_dir = '/var/log/coal',
) {
    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-whisper')
    require_package('python-kafka')
    require_package('python-dateutil')

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
        source => 'puppet:///modules/coal/coal.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Systemd::Service['coal'],
    }

    file { $whisper_dir:
        ensure => directory,
        owner  => 'coal',
        group  => 'coal',
        mode   => '0755',
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'coal',
        group  => 'coal',
        mode   => '0755',
    }

    logrotate::rule { 'coal':
        ensure       => present,
        file_glob    => "${log_dir}/*.log",
        not_if_empty => true,
        max_age      => 30,
        rotate       => 7,
        date_ext     => true,
        compress     => true,
        missing_ok   => true,
    }

    rsyslog::conf { 'coal':
        content  => template('coal/rsyslog.conf.erb'),
        priority => 80,
    }

    systemd::service { 'coal':
        ensure  => present,
        content => systemd_template('coal'),
        restart => true,
        require => [
            User['coal'],
            File[$whisper_dir],
            File[$log_dir],
            File['/usr/local/bin/coal'],
        ],
    }
}
