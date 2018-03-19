class profile::openstack::labtestn::nova::compute::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $network_flat_interface = hiera('profile::openstack::labtestn::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::labtestn::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::labtestn::nova::network_flat_interface_vlan'),
    $network_flat_name = hiera('profile::openstack::labtestn::neutron::network_flat_name'),
    ) {

    $certname = "labvirt-star.${::site}.wmnet"
    $ca_target = '/etc/ssl/certs/wmf_ca_2017_2020.pem'
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        network_flat_name      => $network_flat_name,
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'

    require ::profile::openstack::labtestn::nova::common
    class {'::profile::openstack::base::nova::compute::service':
        version                            => $version,
        certname                           => $certname,
        ca_target                          => $ca_target,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        require                            => Class['::profile::openstack::base::neutron::linuxbridge_agent'],
    }
}
