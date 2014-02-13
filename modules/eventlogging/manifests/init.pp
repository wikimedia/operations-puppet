# == Class: eventlogging
#
# EventLogging is a platform for modeling, logging and processing
# arbitrary analytic data. This Puppet module manages the configuration
# of its event-processing back end.
#
# The back end comprises a suite of service types, each of which
# implements a different task:
#
# [forwarders]    Read line-oriented data via UDP and publish it on a
#                 ZeroMQ TCP socket with the same port number.
#
# [processors]    Decode raw, streaming log data into strictly-validated
#                 JSON objects.
#
# [multiplexers]  Selects multiple ZeroMQ publisher streams into a
#                 single stream.
#
# [consumers]     Data sinks. Consumers subscribe to the parsed and
#                 validated event stream and write it to some medium.
#
# These services communicate with one another using a publisher /
# subscriber model using ØMQ as the transport layer. Different
# event-processing patterns can be implemented by freely composing
# multiple instances of each type, running locally or distributed across
# several hosts.
#
# The /etc/eventlogging.d file hierarchy contains instance definitions.
# It has a subfolder for each service type. An Upstart task,
# 'eventlogging/init', walks this file hierarchy and provisions a
# job for each instance definition. Instance definition files contain
# command-line arguments for the service program, one argument per line.
#
# An 'eventloggingctl' shell script provides a convenient wrapper around
# Upstart's initctl that is specifically tailored for managing
# EventLogging tasks.
#
class eventlogging {
    include eventlogging::package
    include eventlogging::monitor

    # EventLogging jobs set 'eventlogging' gid & uid.
    group { 'eventlogging':
        ensure => present,
    }

    user { 'eventlogging':
        ensure     => present,
        gid        => 'eventlogging',
        shell      => '/bin/false',
        home       => '/srv/eventlogging',
        managehome => true,
        system     => true,
    }

    # The /etc/eventlogging.d file hierarchy contains instance
    # definition files.
    file { [
        '/etc/eventlogging.d',
        '/etc/eventlogging.d/consumers',
        '/etc/eventlogging.d/forwarders',
        '/etc/eventlogging.d/multiplexers',
        '/etc/eventlogging.d/processors'
    ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        before => File['/etc/init/eventlogging'],
    }

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

    # Plug-ins placed in this directory are loaded automatically.
    file { '/usr/local/lib/eventlogging':
        ensure => directory,
    }

    # Logs are collected in </var/log/eventlogging> and rotated daily.
    file { [ '/var/log/eventlogging', '/var/log/eventlogging/archive' ]:
        ensure  => directory,
        owner   => 'eventlogging',
        group   => 'eventlogging',
        mode    => '0664',
    }

    file { '/etc/logrotate.d/eventlogging':
        source  => 'puppet:///modules/eventlogging/logrotate',
        require => File['/var/log/eventlogging/archive'],
        mode    => '0444',
    }
}
