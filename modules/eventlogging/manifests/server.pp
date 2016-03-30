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
# It has a subfolder for each service type. An Upstart task,
# 'eventlogging/init', walks this file hierarchy and provisions a
# job for each instance definition. Instance definition files contain
# command-line arguments for the service program, one argument per line.
#
# An 'eventloggingctl' (in Ubuntu) shell script provides a convenient
# wrapper around Upstart's initctl that is specifically tailored for managing
# EventLogging tasks.
#
# TODO: Port this to Jessie/Systemd.
#
class eventlogging::server {
    require ::eventlogging

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

    logrotate::conf { 'eventlogging':
        ensure  => present,
        content => template('eventlogging/logrotate.erb'),
        require => File[$log_dir],
    }

    # Temporary conditional while we migrate eventlogging service over to
    # using systemd on Debian Jessie.  This will allow us to individually
    # configure services on new nodes while not affecting the running
    # eventlogging analytics instance on Ubuntu Trusty.
    if $::operatingsystem == 'Ubuntu' {
        # Manage EventLogging services with 'eventloggingctl'.
        # Usage: eventloggingctl {start|stop|restart|status|tail}
        file { '/sbin/eventloggingctl':
            source => 'puppet:///modules/eventlogging/eventloggingctl',
            mode   => '0755',
        }

        # Upstart job definitions.
        file { '/etc/init/eventlogging':
            source  => 'puppet:///modules/eventlogging/init',
            recurse => true,
            purge   => true,
            force   => true,
            require => [
                File['/etc/eventlogging.d'],
                File['/etc/eventlogging.d/consumers'],
                File['/etc/eventlogging.d/forwarders'],
                File['/etc/eventlogging.d/multiplexers'],
                File['/etc/eventlogging.d/processors'],
                File['/etc/eventlogging.d/reporters'],
                File['/etc/eventlogging.d/services'],
                Package['eventlogging/eventlogging'],
            ]
        }

        # 'eventlogging/init' is the master upstart task; it walks
        # </etc/eventlogging.d> and starts a job for each instance
        # definition file that it encounters.
        service { 'eventlogging/init':
            provider => 'upstart',
            require  => [
                File['/etc/init/eventlogging'],
                User['eventlogging']
            ],
        }
    }
}
