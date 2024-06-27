# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::nutcracker(
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::codfw1dev::cloudweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        cloudweb_hosts => $cloudweb_hosts,
    }
}
