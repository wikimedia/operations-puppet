class role::labs::openstack::nova::network {

    require openstack
    system::role { $name: }
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    include ::openstack::keystonechecks

    interface::ip { 'openstack::network_service_public_dynamic_snat':
        interface => 'lo',
        address   => $novaconfig['network_public_ip'],
    }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { '::openstack::nova::network':
        novaconfig        => $novaconfig,
    }
}

