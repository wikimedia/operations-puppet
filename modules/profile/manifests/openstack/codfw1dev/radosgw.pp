# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::radosgw (
    String              $version       = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
) {
    class { '::profile::openstack::base::radosgw':
        version       => $version,
        haproxy_nodes => $haproxy_nodes,
    }
}
