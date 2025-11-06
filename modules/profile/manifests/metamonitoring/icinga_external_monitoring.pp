# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::icinga_external_monitoring (
    Wmflib::Ensure                   $ensure           = lookup('profile::metamonitoring::ensure', {default_value => 'present'}),
    String                           $user             = lookup('profile::metamonitoring::user', {default_value => 'prometamon'}),
    Stdlib::Absolutepath             $status_dir       = lookup('profile::metamonitoring::status_dir', { default_value => '/var/lib/o11y-metamonitoring'}),
    Metamonitoring::Vhost_basic_auth $vhost_basic_auth = lookup('profile::metamonitoring::icinga_external_monitoring::vhost_basic_auth'),
) {

  class { 'metamonitoring::icinga_external_monitoring':
      ensure           => $ensure,
      user             => $user,
      status_dir       => $status_dir,
      vhost_basic_auth => $vhost_basic_auth,
  }
}
