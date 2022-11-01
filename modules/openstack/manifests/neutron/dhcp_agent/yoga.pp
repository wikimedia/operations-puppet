# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::yoga(
    $dhcp_domain,
    $report_interval,
) {
    class { "openstack::neutron::dhcp_agent::yoga::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/yoga/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/yoga/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
