class profile::openstack::labtest::nova::network::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_network_host = hiera('profile::openstack::labtest::nova_network_host'),
    $labs_metal = hiera('profile::openstack::labtest::nova::network::labs_metal'),
    $nova_dnsmasq_aliases = hiera('profile::openstack::labtest::nova::network::nova_dnsmasq_aliases'),
    $dns_recursor = hiera('profile::openstack::labtest::nova::network::dns_recursor'),
    $dns_recursor_secondary = hiera('profile::openstack::labtest::nova::network::dns_recursor_secondary'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::labtest::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtest::nova::network_flat_interface_vlan'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::network::service':
        version                            => $version,
        nova_network_host                  => $nova_network_host,
        labs_metal                         => $labs_metal,
        nova_dnsmasq_aliases               => $nova_dnsmasq_aliases,
        dns_recursor                       => $dns_recursor,
        dns_recursor_secondary             => $dns_recursor_secondary,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
    }

    class {'::openstack2::nova::network::monitor':
        active => ($::fqdn == $nova_network_host),
    }
}
