class profile::openstack::base::neutron::l3_agent(
    $version = hiera('profile::openstack::base::version'),
    $dmz_cidr = hiera('profile::openstack::base::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::base::neutron::network_public_ip'),
    $report_interval = hiera('profile::openstack::base::neutron::report_interval'),
    $base_interface = lookup('profile::openstack::base::neutron::base_interface'),
    $network_compat_interface = lookup('profile::openstack::base::neutron::network_compat_interface'),
    $network_compat_interface_vlan = lookup('profile::openstack::base::neutron::network_compat_interface_vlan'),
    $network_flat_interface_external = lookup('profile::openstack::base::neutron::network_flat_interface_external'),
    $network_flat_interface_vlan_external = lookup('profile::openstack::base::neutron::network_flat_interface_vlan_external'),
    $network_flat_interface = lookup('profile::openstack::base::neutron::network_flat_interface'),
    $network_flat_interface_vlan = lookup('profile::openstack::base::neutron::network_flat_interface_vlan'),
    ) {

    interface::tagged { $network_compat_interface:
        base_interface => $base_interface,
        vlan_id        => $network_compat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::tagged { $network_flat_interface_external:
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan_external,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    interface::tagged { $network_flat_interface:
        base_interface => $base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class {'::openstack::neutron::l3_agent':
        version           => $version,
        dmz_cidr_array    => $dmz_cidr,
        network_public_ip => $network_public_ip,
        report_interval   => $report_interval,
    }
    contain '::openstack::neutron::l3_agent'
}
