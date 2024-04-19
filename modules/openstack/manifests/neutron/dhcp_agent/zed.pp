# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::zed(
    $dhcp_domain,
    $report_interval,
    String[1] $interface_driver,
) {
    class { "openstack::neutron::dhcp_agent::zed::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/zed/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/zed/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
