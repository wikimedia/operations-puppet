# == Class: eventlogging::monitoring
#
# This class provisions a Ganglia metric module which reports throughput
# (measured in events per second) of all locally-published event streams.
#
class eventlogging::monitoring {
    include ::eventlogging
    include ::ganglia

    file { '/usr/lib/ganglia/python_modules/eventlogging_mon.py':
        ensure  => present,
        source  => "${eventlogging::package::path}/ganglia/python_modules/eventlogging_mon.py",
        require => Package['python-zmq'],
    }

    file { '/etc/ganglia/conf.d/eventlogging_mon.pyconf':
        ensure  => present,
        source  => 'puppet:///modules/eventlogging/eventlogging_mon.pyconf',
        require => File['/usr/lib/ganglia/python_modules/eventlogging_mon.py'],
        notify  => Service['ganglia-monitor'],
    }

    file { '/usr/lib/nagios/plugins/check_eventlogging_jobs':
        source => 'puppet:///modules/eventlogging/check_eventlogging_jobs',
        mode   => '0755',
    }

    # The EventLogging Ganglia module scans /etc/eventlogging.d
    # to determine which endpoints to monitor, so if the contents
    # of that directory change, the module should be restarted.

    Eventlogging::Service::Multiplexer <| |> ~> Service['ganglia-monitor']
    Eventlogging::Service::Processor <| |> ~> Service['ganglia-monitor']
    Eventlogging::Service::Reporter <| |> ~> Service['ganglia-monitor']
}


# == Class: eventlogging::monitoring::graphite
#
# Provisions a Graphite check for sudden fluctuations in the volume
# of incoming events.
class eventlogging::monitoring::graphite {

    # Warn if 15% of overall event throughput goes beyond 500 events/s
    # in a 15 min period
    # These thresholds are somewhat arbtirary at this point, but it
    # was seen that the current setup can handle 500 events/s.
    # Better thresholds are pending (see T86244).
    monitoring::graphite_threshold { 'eventlogging_throughput':
        description     => 'Throughput of event logging events',
        metric          => 'eventlogging.overall.raw.rate',
        warning         => 500,
        critical        => 600,
        percentage      => 15, # At least 3 of the 15 readings
        from            => '15min',
        contact_group   => 'analytics'
    }

    # Alarms if 15% of Navigation Timing event throughput goes under 1 req/sec
    # in a 15 min period
    # https://meta.wikimedia.org/wiki/Schema:NavigationTiming
    monitoring::graphite_threshold { 'eventlogging_NavigationTiming_throughput':
        description     => 'Throughput of event logging NavigationTiming events',
        metric          => 'eventlogging.schema.NavigationTiming.rate',
        warning         => 1,
        critical        => 0,
        percentage      => 15, # At least 3 of the 15 readings
        from            => '15min',
        contact_group   => 'analytics',
        under           => true
    }

    # Warn/Alert if the difference between raw and valid EventLogging
    # alerts gets too big.
    # If the difference gets too big, either the validation step is
    # overloaded, or high volume schemas are failing validation.
    #
    # Since diffed series are not fully synchronized, the plain diff
    # would gives a trajectory that is flip/flopping above and below
    # zero ~50 events/s. Hence, we average the diff over 10
    # readings. That way, we dampen flip/flopping enough to get a
    # characteristic that is worth alerting on.
    monitoring::graphite_threshold { 'eventlogging_difference_raw_validated':
        description   => 'Difference between raw and validated EventLogging overall message rates',
        metric        => 'movingAverage(diffSeries(eventlogging.overall.raw.rate,eventlogging.overall.valid.rate),10)',
        warning       => 20,
        critical      => 30,
        percentage    => 15, # At least 3 of the 15 readings
        from          => '15min',
        contact_group => 'analytics',
    }
}
