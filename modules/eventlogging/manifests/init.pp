# == Class: eventlogging
#
# EventLogging is a platform for modeling, logging and processing
# arbitrary analytic data. This Puppet module manages the configuration
# of its event processing component, which comprises a suite of four
# services, each of which implements a different step in a data
# processing pipeline. The services communicate with one another using a
# publisher/subscriber model, using ØMQ as the transport layer.
# An arbitrary number of service instances running on an arbitrary
# number of hosts can be freely composed to form different event
# processing patterns.
#
class eventlogging {
    include eventlogging::packages
    include eventlogging::deployment

    group { 'eventlogging':
        ensure => present,
    }

    user { 'eventlogging':
        ensure     => present,
        gid        => 'eventlogging',
        shell      => '/sbin/nologin',
        home       => '/srv/eventlogging',
        managehome => true,
        system     => true,
    }

    file { [
        '/etc/eventlogging.d',
        '/etc/eventlogging.d/consumers',
        '/etc/eventlogging.d/forwarders',
        '/etc/eventlogging.d/multiplexers',
        '/etc/eventlogging.d/processors'
    ]:
        ensure => directory,
        before => File['/etc/init/eventlogging'],
    }


    file { '/etc/init/eventlogging':
        source  => 'puppet:///modules/eventlogging/init',
        recurse => true,
    }

    file { '/sbin/eventloggingctl':
        source => 'puppet:///modules/eventlogging/eventloggingctl',
        mode   => '0755',
    }

    service { 'eventlogging/init':
        provider   => 'upstart',
        require    => [
            File['/etc/init/eventlogging'],
            User['eventlogging']
        ],
    }
}
