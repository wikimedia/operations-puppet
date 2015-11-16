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
# [reporter]      Specialized StatsD clients which report counts of all
#                 incoming events (valid and invalid) to a StatsD host.
#
# These services communicate with one another using a publisher /
# subscriber model using ZeroMQ as the transport layer. Different
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
# An 'eventloggingctl' (in Ubuntu) shell script provides a convenient
# wrapper around Upstart's initctl that is specifically tailored for managing
# EventLogging tasks.
#
class eventlogging {
    require_package([
        'python-dateutil',
        'python-etcd',
        'python-jsonschema',
        'python-kafka',
        'python-mysqldb',
        'python-pygments',
        'python-pykafka',
        'python-pymongo',
        'python-six',
        'python-sqlalchemy',
        'python-statsd',
        'python-yaml',
        'python-zmq',
    ])

    # eventlogging runtime logs go here
    $log_dir = '/var/log/eventlogging'

    # eventlogging content output can go here
    $out_dir = '/srv/log/eventlogging'

    # We ensure the /srv/log (parent of $log_dir) manually here, as
    # there is no proper class to rely on for this, and starting a
    # separate would be an overkill for now.
    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    group { 'eventlogging':
        ensure => present,
    }

    user { 'eventlogging':
        ensure     => present,
        gid        => 'eventlogging',
        shell      => '/bin/false',
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

    # Logs are collected in <$log_dir> and rotated daily.
    file { [
            $log_dir,
            $out_dir,
            "${out_dir}/archive"
        ]:
        ensure => 'directory',
        owner  => 'eventlogging',
        group  => 'eventlogging',
        mode   => '0664',
    }

    file { '/etc/logrotate.d/eventlogging':
        content => template('eventlogging/logrotate.erb'),
        mode    => '0444',
        require => [
            File[$log_dir],
            File["${out_dir}/archive"]
        ],
    }
}
