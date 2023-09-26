# SPDX-License-Identifier: Apache-2.0
class ipmi::monitor (
    Wmflib::Ensure $ensure = 'present'
) {
    ensure_packages(['freeipmi-tools', 'freeipmi-ipmiseld'])

    $ipmiseld_config = @(IPMISELDCONFIG)
        # THIS FILE IS MANAGED BY PUPPET
        interpret-oem-data ENABLE
        entity-sensor-names ENABLE
        | IPMISELDCONFIG

    file { '/etc/freeipmi/ipmiseld.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => $ipmiseld_config,
        require => Package['freeipmi-ipmiseld'],
        notify  => Service['ipmiseld'],
    }

    service { 'ipmiseld':
        ensure  => running,
        enable  => true,
        require => Package['freeipmi-ipmiseld'],
    }

    if debian::codename::ge('bookworm') {
        profile::auto_restarts::service { 'ipmiseld': }
    }

    file { '/var/cache/ipmiseld':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        before => Package['freeipmi-ipmiseld'],
    }

    # ipmi_devintf needs to be loaded for the checks to work properly (T167121)
    nrpe::plugin { 'check_ipmi_sensor':
        ensure => absent,
        source => 'puppet:///modules/base/monitoring/check_ipmi_sensor',
    }

    kmod::module { 'ipmi_devintf':
        ensure => present,
    }

    sudo::user { 'nagios_ipmi_sensor':
        ensure     => absent,
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/ipmi-sel, /usr/sbin/ipmi-sensors'],
    }

    nrpe::monitor_service { 'check_ipmi_sensor':
        ensure         => absent,
        description    => 'IPMI Sensor Status',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_ipmi_sensor --noentityabsent -T Temperature -T Power_Supply --nosel',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Power_Supply_Failures',
    }
}
