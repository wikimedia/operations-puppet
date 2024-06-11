# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::opentofu (
  String[1]    $region            = lookup('profile::openstack::eqiad1::region'),
  Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
) {
  class { 'profile::openstack::base::opentofu':
    region            => $region,
    keystone_api_fqdn => $keystone_api_fqdn,
  }
}
