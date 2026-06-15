# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::api::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    String $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain', {default_value => 'example.com'}),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    Stdlib::Fqdn $keystone_fqdn        = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $observer_password          = lookup('profile::openstack::eqiad1::observer_password'),
    String $region                     = lookup('profile::openstack::eqiad1::region'),
    Array[Stdlib::IP::Address] $cloud_cumin_bastions = lookup('profile::openstack::eqiad1::cloud_cumin_bastions'),
) {
    require ::profile::openstack::eqiad1::nova::common
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
