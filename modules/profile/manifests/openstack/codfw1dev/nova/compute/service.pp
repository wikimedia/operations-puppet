class profile::openstack::codfw1dev::nova::compute::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $network_flat_interface = hiera('profile::openstack::codfw1dev::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::codfw1dev::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::codfw1dev::nova::network_flat_interface_vlan'),
    $network_flat_name = hiera('profile::openstack::codfw1dev::neutron::network_flat_name'),
    $physical_interface_mappings = hiera('profile::openstack::codfw1dev::nova::physical_interface_mappings'),
    ) {

    $certname = "labvirt-star.${::site}.wmnet"
    $ca_target = '/etc/ssl/certs/wmf_ca_2017_2020.pem'
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version                     => $version,
        physical_interface_mappings => $physical_interface_mappings,
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::compute::service':
        version                            => $version,
        certname                           => $certname,
        ca_target                          => $ca_target,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        require                            => Class['::profile::openstack::base::neutron::linuxbridge_agent'],
    }
    contain '::profile::openstack::base::nova::compute::service'
}
