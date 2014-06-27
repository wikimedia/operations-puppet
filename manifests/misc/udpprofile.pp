
class udpprofile::collector {
    system::role { 'udpprofile::collector': description => 'MediaWiki UDP profile collector' }

    package { 'udpprofile':
        ensure => latest;
    }

    service { 'udpprofile':
        require => Package[ 'udpprofile' ],
        enable  => true,
        ensure  => running;
    }

    # Nagios monitoring (RT-2367)
    nrpe::monitor_service { 'carbon-cache':
        description  => 'carbon-cache.py',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:2 -a carbon-cache.py',
    }
    nrpe::monitor_service { 'profiler-to-carbon':
        description   => 'profiler-to-carbon',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^/usr/bin/python /usr/udpprofile/sbin/profiler-to-carbon",
    }
    nrpe::monitor_service { 'profiling collector':
        description  => 'profiling collector',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:20 -C collector',
    }
}
