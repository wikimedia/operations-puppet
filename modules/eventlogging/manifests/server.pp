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

    logrotate::conf { 'eventlogging':
        ensure         => present,
        file_pattern   => "${log_dir}/*.log",
        not_if_empty   => true,
        max_age        => 30,
        rotate         => 2,
        date_ext       => true,
        compress       => true,
        delay_compress => true,
        missing_ok     => true,
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
            ensure  => 'directory',
            recurse => true,
            purge   => true,
            force   => true,
        }
        file { '/etc/init/eventlogging/init.conf':
            content => template('eventlogging/upstart/init.conf.erb'),
        }
        file { '/etc/init/eventlogging/consumer.conf':
            content => template('eventlogging/upstart/consumer.conf.erb'),
            require => File['/etc/eventlogging.d/consumers'],
        }
        file { '/etc/init/eventlogging/forwarder.conf':
            content => template('eventlogging/upstart/forwarder.conf.erb'),
            require => File['/etc/eventlogging.d/forwarders'],
        }
        file { '/etc/init/eventlogging/multiplexer.conf':
            content => template('eventlogging/upstart/multiplexer.conf.erb'),
            require => File['/etc/eventlogging.d/multiplexers'],
        }
        file { '/etc/init/eventlogging/processor.conf':
            content => template('eventlogging/upstart/processor.conf.erb'),
            require => File['/etc/eventlogging.d/processors'],
        }
        file { '/etc/init/eventlogging/reporter.conf':
            content => template('eventlogging/upstart/reporter.conf.erb'),
            require => File['/etc/eventlogging.d/reporters'],
        }
        # daemon service http service is not supported using upstart.
        # See: eventlogging::service::service

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
