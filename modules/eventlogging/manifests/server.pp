# == Class eventlogging::server
#
# Installs eventlogging package and depdendencies and
# configures this box to daemonize and run eventlogging
# services.
#
# The back end comprises a suite of service types, each of which
# implements a different task:
#
# [forwarders]    Read in line-oriented data and publish them to an output.
#
# [processors]    Decode raw, streaming log data into strictly-validated
#                 JSON objects.
#
# [multiplexers]  Selects multiple input streams and publishes them into
#                 a single output stream.
#
# [consumers]     Data sinks. Consumers subscribe to a parsed and
#                 validated event stream and write it to some medium.
#
# [reporters]     Specialized StatsD clients which report counts of all
#                 incoming  events (valid and invalid) to a StatsD host.
#                 NOTE: This only works with 0MQ processors, which are
#                 no longer used at WMF.
#
# [services]      HTTP Service that accepts events via HTTP post.
#                 The events are validated before being produced
#                 to configured output streams.
#
# These services communicate with one another using a publisher /
# subscriber model. Different event-processing patterns can be
# implemented by freely composing multiple instances of each type,
# running locally or distributed across several hosts.
#
# The /etc/eventlogging.d file hierarchy contains instance definitions.
# It has a subfolder for each service type.
#
# An 'eventloggingctl' shell script provides a convenient wrapper around
# Systemd units, that is specifically tailored for managing EventLogging tasks.
#
# == Parameters
#
# [*eventlogging_path*]
#   Path to eventlogging codebase
#   Default: /srv/deployment/eventlogging/eventlogging
#
# [*log_dir*]
#   Log directory in which all the systemd daemons will log their
#   output. It creates recursively the missing directories if needed.
#   Default: '/var/log/eventlogging/systemd'
#
class eventlogging::server(
    $eventlogging_path    = '/srv/deployment/eventlogging/eventlogging',
    $log_dir              = '/srv/log/eventlogging/systemd',
    $ensure               = 'present',
    $python_kafka_version = 'present',
)
{
    # Ensure python-kafka for eventlogging
    # is at 1.4.1.  There is an upstream bug
    # https://github.com/dpkp/kafka-python/issues/1418.
    # Our apt repo (as of 2019-09) has python-kafka 1.4.6
    # for use with coal.  We want to ensure we
    # don't accidentally upgrade on eventloggging
    # until this is fixed.
    # See also: https://phabricator.wikimedia.org/T222941
    class { '::eventlogging::dependencies':
        python_kafka_version => $python_kafka_version,
    }

    group { 'eventlogging':
        ensure => $ensure,
    }

    user { 'eventlogging':
        ensure     => $ensure,
        gid        => 'eventlogging',
        shell      => '/bin/bash',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    $eventlogging_directories = [
        '/etc/eventlogging.d',
        '/etc/eventlogging.d/consumers',
        '/etc/eventlogging.d/forwarders',
        '/etc/eventlogging.d/multiplexers',
        '/etc/eventlogging.d/processors',
        '/etc/eventlogging.d/reporters',
        '/etc/eventlogging.d/services',
    ]

    # Instance definition files.
    file { $eventlogging_directories:
        ensure  => ensure_directory($ensure),
        recurse => true,
        purge   => true,
        force   => true,
    }


    # Plug-ins placed in this directory are loaded automatically.
    file { '/usr/local/lib/eventlogging':
        ensure => ensure_directory($ensure)
    }

    # This directory is useful for various components of
    # eventlogging, so we use this class as central creation
    # point due to the fact that it needs to be included
    # everywhere.
    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => ensure_directory($ensure),
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    # Logs are collected in <$log_dir> and rotated daily.
    file { $log_dir:
        ensure  => ensure_directory($ensure),
        owner   => 'eventlogging',
        group   => 'eventlogging',
        recurse => true,
        mode    => '0644',
        require => File['/srv/log'],
    }

    logrotate::rule { 'eventlogging':
        ensure       => $ensure,
        file_glob    => "${log_dir}/*.log",
        not_if_empty => true,
        max_age      => 30,
        rotate       => 4,
        date_ext     => true,
        compress     => true,
        missing_ok   => true,
        size         => '100M',
    }

    systemd::service { 'eventlogging':
        ensure  => $ensure,
        content => systemd_template('eventlogging'),
        restart => true,
        require => User['eventlogging'],
    }

    file { '/sbin/eventloggingctl':
        ensure => $ensure,
        source => 'puppet:///modules/eventlogging/eventloggingctl.systemd',
        mode   => '0755',
    }
}
