class pybal {
    package { [ 'ipvsadm', 'pybal' ]:
        ensure => installed,
    }

    file { '/etc/default/pybal':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/pybal/default',
        require => Package['pybal'],
    }

    service { 'pybal':
        ensure  => running,
        enable  => true,
        require => File['/etc/default/pybal'],
    }

    rsyslog::conf { 'pybal':
        source   => 'puppet:///modules/pybal/pybal.rsyslog.conf',
        priority => 75,
        before   => Service['pybal'],
    }

    file { '/etc/logrotate.d/pybal':
        ensure => present,
        source => 'puppet:///modules/pybal/pybal.logrotate.conf',
        mode   => '0444',
    }

    nrpe::monitor_service { 'pybal':
        description  => 'pybal',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u root -a /usr/sbin/pybal',
    }
}
