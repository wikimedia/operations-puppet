class profile::openstack::base::neutron::l3_agent(
    $version = lookup('profile::openstack::base::version'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::base::neutron::base_interface'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::base::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface_vlan = lookup('profile::openstack::base::neutron::network_flat_interface_vlan'),
    $legacy_vlan_naming = lookup('profile::openstack::base::neutron::legacy_vlan_naming'),
    ) {

    interface::tagged { "${base_interface}.${$network_flat_interface_vlan_external}":
        base_interface     => $base_interface,
        vlan_id            => $network_flat_interface_vlan_external,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => $legacy_vlan_naming,
    }

    interface::tagged { "${base_interface}.${$network_flat_interface_vlan}":
        base_interface     => $base_interface,
        vlan_id            => $network_flat_interface_vlan,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => $legacy_vlan_naming,
    }

    class {'::openstack::neutron::l3_agent':
        version         => $version,
        report_interval => $report_interval,
        nic_dataplane   => $base_interface,
        wan_vlan        => $network_flat_interface_vlan_external,
        virt_vlan       => $network_flat_interface_vlan,
    }
    contain '::openstack::neutron::l3_agent'

    class { '::prometheus::node_neutron_namespace':
        ensure => 'present',
    }
}
