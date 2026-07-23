# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::serverpackages(
    String $version = lookup('profile::openstack::base::version'),
) {
    class { "::openstack::serverpackages::${version}::${facts['os']['distro']['codename']}":
    }
}
