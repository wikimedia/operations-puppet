# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::caracal(
    $report_interval,
    Enum['linuxbridge', 'openvswitch'] $interface_driver,
) {
    class { "openstack::neutron::l3_agent::caracal::${::lsbdistcodename}": }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0640',
            content => template('openstack/caracal/neutron/l3_agent.ini.erb'),
            require => Package['neutron-l3-agent'];
    }

    # neutron-l3-agent Depends radvd on stein, but we don't use and don't
    # configure it. To prevent icinga from reporting a unit in bad shape, just
    # disable it.
    systemd::mask { 'radvd.service':
        before => Package['neutron-l3-agent'],
    }
}
