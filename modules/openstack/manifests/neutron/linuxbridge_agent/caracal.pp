# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::linuxbridge_agent::caracal(
    $report_interval,
    $bridge_mappings={},
    $physical_interface_mappings={},
) {
    class { "openstack::neutron::linuxbridge_agent::caracal::${::lsbdistcodename}": }

    file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        content => template('openstack/caracal/neutron/plugins/ml2/linuxbridge_agent.ini.erb'),
        require => Package['neutron-linuxbridge-agent'],
    }
}
