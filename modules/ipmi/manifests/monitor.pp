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

    # TODO: Verify if ipmi-exporter needs this module to work
    kmod::module { 'ipmi_devintf':
        ensure => present,
    }
}
