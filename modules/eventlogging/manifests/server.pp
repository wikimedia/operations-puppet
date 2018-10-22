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
class eventlogging::server(
    $eventlogging_path   = '/srv/deployment/eventlogging/eventlogging',
)
{
    require ::eventlogging::dependencies

    group { 'eventlogging':
        ensure => present,
    }

    user { 'eventlogging':
        ensure     => 'present',
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
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
    }


    # Plug-ins placed in this directory are loaded automatically.
    file { '/usr/local/lib/eventlogging':
        ensure => directory,
    }

    # In Jessie/Systemd, eventlogging runtime logs go here
    $log_dir = '/var/log/eventlogging'

    # Logs are collected in <$log_dir> and rotated daily.
    file { $log_dir:
        ensure => 'directory',
        owner  => 'eventlogging',
        group  => 'eventlogging',
        mode   => '0644',
    }

    logrotate::rule { 'eventlogging':
        ensure       => present,
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
        ensure  => present,
        content => systemd_template('eventlogging'),
        restart => true,
        require => User['eventlogging'],
    }

    file { '/sbin/eventloggingctl':
        source => 'puppet:///modules/eventlogging/eventloggingctl.systemd',
        mode   => '0755',
    }
}
