class ipmi::monitor (
    Wmflib::Ensure $ensure = 'present'
) {
    ensure_packages(['freeipmi-tools'])

    # install ipmiseld on hardware to log ipmi system event log entries to syslog
    ensure_packages('freeipmi-ipmiseld')

    profile::auto_restarts::service { 'ipmiseld':
        ensure => absent,
    }

    # ensure service only on buster as other OS versions are conigured properly by the package
    if debian::codename::eq('buster') {
        service { 'ipmiseld':
            ensure => running,
            enable => true,
        }
    }

    file { '/var/cache/ipmiseld':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        before => Package['freeipmi-ipmiseld'],
    }

    # ipmi_devintf needs to be loaded for the checks to work properly (T167121)
    nrpe::plugin { 'check_ipmi_sensor':
        source => 'puppet:///modules/base/monitoring/check_ipmi_sensor',
    }

    kmod::module { 'ipmi_devintf':
        ensure => present,
    }

    sudo::user { 'nagios_ipmi_sensor':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/ipmi-sel, /usr/sbin/ipmi-sensors'],
    }

    nrpe::monitor_service { 'check_ipmi_sensor':
        ensure         => $ensure,
        description    => 'IPMI Sensor Status',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_ipmi_sensor --noentityabsent -T Temperature -T Power_Supply --nosel',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Power_Supply_Failures',
    }
}
