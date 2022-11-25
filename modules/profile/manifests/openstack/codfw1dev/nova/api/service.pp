# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::nova::api::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    String $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain', {default_value => 'example.com'}),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
) {
    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::api::service':
        version       => $version,
        dhcp_domain   => $dhcp_domain,
        haproxy_nodes => $haproxy_nodes,
    }
}
