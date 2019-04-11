class profile::openstack::main::nova::network::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_network_host = hiera('profile::openstack::main::nova_network_host'),
    $dns_recursor = hiera('profile::openstack::main::pdns::recursor'),
    $dns_recursor_secondary = hiera('profile::openstack::main::pdns::recursor_secondary'),
    $network_flat_interface = hiera('profile::openstack::main::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::main::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::main::nova::network_flat_interface_vlan'),
    $network_public_ip = hiera('profile::openstack::main::nova::network_public_ip'),
    $dnsmasq_classles_static_route = hiera('profile::openstack::main::nova::dnsmasq_classles_static_route'),
    ) {

    require ::profile::openstack::main::nova::common
    class {'::profile::openstack::base::nova::network::service':
        version                            => $version,
        nova_network_host                  => $nova_network_host,
        dns_recursor                       => $dns_recursor,
        dns_recursor_secondary             => $dns_recursor_secondary,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        network_public_ip                  => $network_public_ip,
        dnsmasq_classles_static_route      => $dnsmasq_classles_static_route,
    }

    if ($::fqdn == $nova_network_host) {
        class {'::openstack::nova::network::monitor':
            critical       => true,
            contact_groups => 'wmcs-team',
        }
    }
}
