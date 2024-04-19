# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::antelope(
    $dhcp_domain,
    $report_interval,
    String[1] $interface_driver,
) {
    class { "openstack::neutron::dhcp_agent::antelope::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/antelope/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/antelope/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
