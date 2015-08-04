class pybal {
    package { [ 'ipvsadm', 'pybal' ]:
        ensure => installed,
    }

    service { 'pybal':
        ensure => running,
        enable => true,
    }

    nrpe::monitor_service { 'pybal':
        description  => 'pybal',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a /usr/sbin/pybal',
    }
}
