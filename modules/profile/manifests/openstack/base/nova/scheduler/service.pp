# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::scheduler::service(
    $version = lookup('profile::openstack::base::version'),
    ) {

    class {'::openstack::nova::scheduler::service':
        active  => true,
        version => $version,
    }
    contain '::openstack::nova::scheduler::service'
}
