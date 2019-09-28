# The stock l3-agent from Neutron is missing features
# that were available in nova-network.
# These are modified source files for the base router class
# that allow us to implement these features.
#
# T167357 T168580

class openstack::neutron::l3_agent::mitaka::l3_agent_hacks() {

    file { '/usr/lib/python2.7/dist-packages/neutron/agent/l3/config.py':
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/openstack/mitaka/neutron/l3/config.py',
    }

    file { '/usr/lib/python2.7/dist-packages/neutron/agent/l3/router_info.py':
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/openstack/mitaka/neutron/l3/router_info.py',
    }
}
