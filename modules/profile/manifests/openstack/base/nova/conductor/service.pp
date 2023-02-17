# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::conductor::service(
    $version = lookup('profile::openstack::base::version'),
    ) {

    class {'::openstack::nova::conductor::service':
        version => $version,
        active  => true,
    }
    contain '::openstack::nova::conductor::service'
}
