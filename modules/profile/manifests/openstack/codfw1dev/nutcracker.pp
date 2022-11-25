# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::nutcracker(
    $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
) {
    class {'profile::openstack::base::nutcracker':
        labweb_hosts => lookup('profile::openstack::codfw1dev::labweb_hosts'),
    }
}
