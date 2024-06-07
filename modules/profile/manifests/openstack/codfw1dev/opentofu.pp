# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::opentofu (
  String[1]    $region            = lookup('profile::openstack::codfw1dev::region'),
  Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
) {
  class { 'profile::openstack::base::opentofu':
    region            => $region,
    keystone_api_fqdn => $keystone_api_fqdn,
  }
}
