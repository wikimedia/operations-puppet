# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::api::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    String $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain', {default_value => 'example.com'}),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
) {
    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version       => $version,
        dhcp_domain   => $dhcp_domain,
        haproxy_nodes => $haproxy_nodes,
    }
}
