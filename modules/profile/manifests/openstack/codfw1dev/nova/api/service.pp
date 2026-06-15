# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::nova::api::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    String $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain', {default_value => 'example.com'}),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
    Stdlib::Fqdn $keystone_fqdn        = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $observer_password          = lookup('profile::openstack::codfw1dev::observer_password'),
    String $region                     = lookup('profile::openstack::codfw1dev::region'),
    Array[Stdlib::IP::Address] $cloud_cumin_bastions = lookup('profile::openstack::codfw1dev::cloud_cumin_bastions'),
) {
    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::api::service':
        version              => $version,
        dhcp_domain          => $dhcp_domain,
        haproxy_nodes        => $haproxy_nodes,
        keystone_fqdn        => $keystone_fqdn,
        observer_password    => $observer_password,
        region               => $region,
        cloud_cumin_bastions => $cloud_cumin_bastions,
    }
}
