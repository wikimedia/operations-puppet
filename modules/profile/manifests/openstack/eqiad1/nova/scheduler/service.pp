# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::scheduler::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::scheduler::service':
        version         => $version,
    }
}
