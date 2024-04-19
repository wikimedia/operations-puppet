# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::nova::compute::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    String[1] $network_flat_interface = lookup('profile::openstack::codfw1dev::nova::network_flat_interface'),
    Optional[String[1]] $network_flat_tagged_base_interface = lookup('profile::openstack::codfw1dev::nova::network_flat_tagged_base_interface', {default_value => undef}),
    $network_flat_interface_vlan = lookup('profile::openstack::codfw1dev::nova::network_flat_interface_vlan'),
    $network_flat_name = lookup('profile::openstack::codfw1dev::neutron::network_flat_name'),
    $physical_interface_mappings = lookup('profile::openstack::codfw1dev::nova::physical_interface_mappings'),
    String $libvirt_cpu_model = lookup('profile::openstack::codfw1dev::nova::libvirt_cpu_model'),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks_internal = lookup('profile::openstack::codfw1dev::neutron::provider_networks_internal', {default_value => {}}),
    Boolean $use_ovs = lookup('profile::openstack::codfw1dev::neutron::use_ovs', {default_value => false}),
) {

    require ::profile::openstack::codfw1dev::neutron::common
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

    require ::profile::openstack::codfw1dev::nova::common
    $all_cloudvirts = unique(
        wmflib::class::hosts('profile::openstack::codfw1dev::nova::compute::service') << $facts['networking']['fqdn']
    ).sort
    class { 'profile::openstack::base::nova::compute::service':
        version                            => $version,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        all_cloudvirts                     => $all_cloudvirts,
        libvirt_cpu_model                  => $libvirt_cpu_model,
    }
    contain '::profile::openstack::base::nova::compute::service'

}
