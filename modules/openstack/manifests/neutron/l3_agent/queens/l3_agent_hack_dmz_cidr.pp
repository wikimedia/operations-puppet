class openstack::neutron::l3_agent::queens::l3_agent_hack_dmz_cidr (
) {
    file { '/usr/lib/python3/dist-packages/neutron/conf/agent/l3/config.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/queens/neutron/l3/only_dmz_cidr/config.py',
            require => Package['neutron-l3-agent'],
    }

    file { '/usr/lib/python3/dist-packages/neutron/agent/l3/router_info.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/queens/neutron/l3/only_dmz_cidr/router_info.py',
            require => Package['neutron-l3-agent'],
    }
}
