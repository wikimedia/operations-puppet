# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::zed(
    $report_interval,
    Enum['linuxbridge', 'openvswitch'] $interface_driver,
) {
    class { "openstack::neutron::l3_agent::zed::${::lsbdistcodename}": }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0640',
            content => template('openstack/zed/neutron/l3_agent.ini.erb'),
            require => Package['neutron-l3-agent'];
    }

    # neutron-l3-agent Depends radvd on stein, but we don't use and don't
    # configure it. To prevent icinga from reporting a unit in bad shape, just
    # disable it.
    systemd::mask { 'radvd.service':
        before => Package['neutron-l3-agent'],
    }

    # hope we only need this for zed, and next version includes the fix
    openstack::patch {'/usr/lib/python3/dist-packages/neutron/agent/l3/keepalived_state_change.py':
        source  => 'puppet:///modules/openstack/zed/neutron/hacks/keepalived_state_change.py.patch',
        require => Package['neutron-l3-agent'],
    }
}
