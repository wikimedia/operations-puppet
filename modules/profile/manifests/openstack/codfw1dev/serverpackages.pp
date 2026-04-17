# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::serverpackages(
    String $version = lookup('profile::openstack::codfw1dev::version'),
) {
    class {'::profile::openstack::base::serverpackages':
        version    => $version,
    }
}
