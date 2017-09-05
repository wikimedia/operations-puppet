class profile::openstack::base::nova::network::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_network_host = hiera('profile::openstack::base::nova_network_host'),
    $labs_metal = hiera('profile::openstack::base::nova::network::labs_metal'),
    $nova_dnsmasq_aliases = hiera('profile::openstack::base::nova::network::nova_dnsmasq_aliases'),
    $dns_recursor = hiera('profile::openstack::base::nova::network::dns_recursor'),
    $dns_recursor_secondary = hiera('profile::openstack::base::nova::network::dns_recursor_secondary'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::base::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::base::nova::network_flat_interface_vlan'),
    $network_public_ip = hiera('profile::openstack::labtestn::nova::network_public_ip'),
    ) {

    interface::ip { 'openstack::network_service_public_dynamic_snat':
        interface => 'lo',
        address   => $network_public_ip,
    }

    interface::tagged { $network_flat_interface:
        base_interface => $network_flat_tagged_base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class {'openstack2::nova::network::service':
        active                 => $::fqdn == $nova_network_host,
        version                => $version,
        labs_metal             => $labs_metal,
        nova_dnsmasq_aliases   => $nova_dnsmasq_aliases,
        dns_recursor           => $dns_recursor,
        dns_recursor_secondary => $dns_recursor_secondary,
    }
}
