class profile::openstack::labtest::nova::compute::service(
    $version = hiera('profile::openstack::labtest::version'),
    $network_flat_interface = hiera('profile::openstack::labtest::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::labtest::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtest::nova::network_flat_interface_vlan'),
    ) {

    $certname = "labvirt-star.${::site}.wmnet"
    $ca_target = '/etc/ssl/certs/wmf_ca_2017_2020.pem'

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::compute::service':
        version                            => $version,
        certname                           => $certname,
        ca_target                          => $ca_target,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
    }
    contain '::profile::openstack::base::nova::compute::service'

    class {'::openstack::nova::compute::monitor':
        active   => true,
        certname => $certname,
    }
    contain '::openstack::nova::compute::monitor'
}
