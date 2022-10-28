# SPDX-License-Identifier: Apache-2.0
# @summary a profile to allow one to create firewall rules via hiera.  usefull for cloud hosts
# @param rules a hash of rules passed to ferm::rule
class profile::base::firewall::extra (
  Hash $services = lookup('profile::base::firewall::extra::services')
) {
  $services.each |$service, $config| {
    ferm::service {$service:
      * => $config
    }
  }
}
