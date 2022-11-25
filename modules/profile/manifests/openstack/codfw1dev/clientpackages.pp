# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::clientpackages(
    String $version = lookup('profile::openstack::codfw1dev::version'),
){
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
