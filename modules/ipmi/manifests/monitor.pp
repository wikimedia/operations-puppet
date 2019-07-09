class ipmi::monitor {
    require_package('freeipmi-tools')

    # ipmi_devintf needs to be loaded for the checks to work properly (T167121)
    file { '/usr/local/lib/nagios/plugins/check_ipmi_sensor':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_ipmi_sensor',
    }

    kmod::module { 'ipmi_devintf':
        ensure => present,
    }

    # rename nagios_ipmi_temp to nagios_ipmi_sensor
    # this ensure absent can be removed after propagation
    ::sudo::user { 'nagios_ipmi_temp':
        ensure     => absent,
        privileges => ['ALL = NOPASSWD: /usr/sbin/ipmi-sel, /usr/sbin/ipmi-sensors'],
    }

    ::sudo::user { 'nagios_ipmi_sensor':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/ipmi-sel, /usr/sbin/ipmi-sensors'],
    }

    nrpe::monitor_service { 'check_ipmi_sensor':
        description    => 'IPMI Sensor Status',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_ipmi_sensor --noentityabsent -T Temperature -T Power_Supply --nosel',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Power_Supply_Failures',
    }
}
