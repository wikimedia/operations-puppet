class profile::openstack::labtest::nova::network::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_network_host = hiera('profile::openstack::labtest::nova_network_host'),
    $dns_recursor = hiera('profile::openstack::labtest::pdns::recursor'),
    $dns_recursor_secondary = hiera('profile::openstack::labtest::pdns::recursor_secondary'),
    $network_flat_interface = hiera('profile::openstack::labtest::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::labtest::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtest::nova::network_flat_interface_vlan'),
    $network_public_ip = hiera('profile::openstack::labtest::nova::network_public_ip'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::network::service':
        version                            => $version,
        nova_network_host                  => $nova_network_host,
        dns_recursor                       => $dns_recursor,
        dns_recursor_secondary             => $dns_recursor_secondary,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        network_public_ip                  => $network_public_ip,
    }
    contain '::profile::openstack::base::nova::network::service'

    class {'::openstack::nova::network::monitor':
        active => ($::fqdn == $nova_network_host),
    }
    contain '::openstack::nova::network::monitor'
}
