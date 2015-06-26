# == Class: eventlogging::monitoring::ganglia
#
# This class provisions a Ganglia metric module which reports throughput
# (measured in events per second) of all locally-published event streams.
#
class eventlogging::monitoring::ganglia {
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
    # The EventLogging Ganglia module scans /etc/eventlogging.d
    # to determine which endpoints to monitor, so if the contents
    # of that directory change, the module should be restarted.

    Eventlogging::Service::Multiplexer <| |> ~> Service['ganglia-monitor']
    Eventlogging::Service::Processor <| |> ~> Service['ganglia-monitor']
    Eventlogging::Service::Reporter <| |> ~> Service['ganglia-monitor']
}
