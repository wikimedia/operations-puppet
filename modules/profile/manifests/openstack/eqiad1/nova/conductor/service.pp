# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::nova::conductor::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
    }
}
