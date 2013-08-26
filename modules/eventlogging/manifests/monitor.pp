# == Class: eventlogging::monitor
#
# This class provisions a Ganglia metric module which reports throughput
# (measured in events per second) of all locally-published event streams.
#
class eventlogging::monitor {
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
