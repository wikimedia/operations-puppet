# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::serverpackages(
    String $version = lookup('profile::openstack::eqiad1::version'),
) {
    class {'::profile::openstack::base::serverpackages':
        version    => $version,
    }
}
