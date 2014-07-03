# == Class: eventlogging::monitoring
#
# This class provisions a Ganglia metric module which reports throughput
# (measured in events per second) of all locally-published event streams.
#
class eventlogging::monitoring {
    include eventlogging

    file { '/usr/lib/ganglia/python_modules/eventlogging_mon.py':
        ensure  => present,
        source  => "${eventlogging::package::path}/ganglia/python_modules/eventlogging_mon.py",
        require => Package['python-zmq'],
    }

    file { '/etc/ganglia/conf.d/eventlogging_mon.pyconf':
        ensure  => present,
        source  => 'puppet:///modules/eventlogging/eventlogging_mon.pyconf',
        require => File['/usr/lib/ganglia/python_modules/eventlogging_mon.py'],
        notify  => Service['gmond'],
    }

    file { '/usr/lib/nagios/plugins/check_eventlogging_jobs':
        source => 'puppet:///modules/eventlogging/check_eventlogging_jobs',
        mode   => '0755',
    }
}


# == Class: eventlogging::monitoring::graphite
#
# Provisions a Graphite check for sudden fluctuations in the volume
# of incoming events.
class eventlogging::monitoring::graphite {

    # Alarms if 1% of overall event throughput goes beyond 350 req/sec
    # in a 15 min period
    monitor_graphite_threshold { 'eventlogging_throughput':
        description     => 'Throughput of event logging events',
        metric          => 'eventlogging.overall.raw.rate',
        warning         => 350,
        critical        => 500,
        from            => '15min',
        contact_group   => 'analytics'
    }

    # Alarms if 1% of Navigation Timing event throughput goes under 2 req/sec
    # in a 15 min period
    # https://meta.wikimedia.org/wiki/Schema:NavigationTiming
    
    # Note:
    # you can test this via doing:
    #  ./files/icinga/check_graphite 
    # --url http://graphite.wikimedia.org check_threshold
    # eventlogging.schema.NavigationTiming.rate --from 15min -C 1 -W 2 --under
    # it will report the following:
    # OK: Less than 1.00% data above the threshold [2.0]
    # but actually the check is correct is checking points below threshold
    monitor_graphite_threshold { 'eventlogging_throughput':
        description     => 'Throughput of event logging NavigationTiming events',
        metric          => 'eventlogging.schema.NavigationTiming.rate',
        warning         => 2,
        critical        => 1,
        from            => '15min',
        contact_group   => 'analytics',
        under           => 'true'
    }
}
