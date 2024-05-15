# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::compute::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    String[1] $network_flat_interface = lookup('profile::openstack::eqiad1::nova::network_flat_interface'),
    Optional[String[1]] $network_flat_tagged_base_interface = lookup('profile::openstack::eqiad1::nova::network_flat_tagged_base_interface', {default_value => undef}),
    $network_flat_interface_vlan = lookup('profile::openstack::eqiad1::nova::network_flat_interface_vlan'),
    $network_flat_name = lookup('profile::openstack::eqiad1::neutron::network_flat_name'),
    $physical_interface_mappings = lookup('profile::openstack::eqiad1::nova::physical_interface_mappings'),
    String $libvirt_cpu_model = lookup('profile::openstack::eqiad1::nova::libvirt_cpu_model'),
    Optional[Boolean] $enable_nova_rbd = lookup('profile::cloudceph::client::rbd::enable_nova_rbd', {'default_value' => false}),
    Optional[String] $ceph_rbd_pool = lookup('profile::cloudceph::client::rbd::pool', {'default_value' => undef}),
    Optional[String] $ceph_rbd_client_name = lookup('profile::cloudceph::client::rbd::client_name', {'default_value' => undef}),
    Optional[String] $libvirt_rbd_uuid = lookup('profile::cloudceph::client::rbd::libvirt_rbd_uuid', {'default_value' => undef}),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_internal = lookup('profile::openstack::eqiad1::neutron::provider_networks_internal', {default_value => {}}),
    Boolean $use_ovs = lookup('profile::openstack::eqiad1::neutron::use_ovs', {default_value => false}),
    ) {

    require ::profile::openstack::eqiad1::neutron::common
    if $use_ovs {
        class { 'profile::openstack::base::neutron::ovs_agent':
            version           => $version,
            provider_networks => $provider_networks_internal,
            before            => Class['profile::openstack::base::nova::compute::service'],
        }
    } else {
        class {'::profile::openstack::base::neutron::linuxbridge_agent':
            version                     => $version,
            physical_interface_mappings => $physical_interface_mappings,
            before                      => Class['profile::openstack::base::nova::compute::service'],
        }
        contain '::profile::openstack::base::neutron::linuxbridge_agent'
    }

    require ::profile::openstack::eqiad1::nova::common
    $all_cloudvirts = unique(
        wmflib::class::hosts('profile::openstack::eqiad1::nova::compute::service') << $facts['networking']['fqdn']
    ).sort
    class {'::profile::openstack::base::nova::compute::service':
        version                            => $version,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        all_cloudvirts                     => $all_cloudvirts,
        libvirt_cpu_model                  => $libvirt_cpu_model,
        require                            => Class['::profile::openstack::base::neutron::linuxbridge_agent'],
        ceph_rbd_pool                      => $ceph_rbd_pool,
        ceph_rbd_client_name               => $ceph_rbd_client_name,
        libvirt_rbd_uuid                   => $libvirt_rbd_uuid,
        enable_nova_rbd                    => $enable_nova_rbd,
    }
    contain '::profile::openstack::base::nova::compute::service'

    class {'::openstack::nova::compute::monitor':
        active           => true,
        verify_instances => true,
        contact_groups   => 'wmcs-team,admins',
    }
    contain '::openstack::nova::compute::monitor'
}
