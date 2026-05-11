# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::l3_agent(
    $version = lookup('profile::openstack::base::version'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::base::neutron::base_interface'),
    Network::VLANTag $network_flat_interface_vlan_external = lookup('profile::openstack::base::neutron::network_flat_interface_vlan_external'),
    Network::VLANTag $network_flat_interface_vlan = lookup('profile::openstack::base::neutron::network_flat_interface_vlan'),
) {
    $wan_nic  = "vlan${network_flat_interface_vlan_external}"
    $virt_nic = "vlan${network_flat_interface_vlan}"

    interface::tagged { $wan_nic:
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan_external,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::tagged { $virt_nic:
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::mtu { [ $wan_nic, $virt_nic ]:
        mtu => 1500,
    }

    class {'::openstack::neutron::l3_agent':
        version         => $version,
        report_interval => $report_interval,
        wan_nic         => $wan_nic,
        virt_nic        => $virt_nic,
    }
    contain '::openstack::neutron::l3_agent'

    class { '::prometheus::node_neutron_namespace':
        ensure => 'present',
    }
}
