# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::deadmanswitchamhook (
    Wmflib::Ensure       $ensure         = lookup('profile::metamonitoring::ensure', {default_value => 'present'}),
    String               $user           = lookup('profile::metamonitoring::user', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $status_dir     = lookup('profile::metamonitoring::status_dir', { default_value => '/var/lib/o11y-metamonitoring'}),
    Stdlib::Absolutepath $log_dir        = lookup('profile::metamonitoring::log_dir', { default_value => '/var/log/o11y-metamonitoring'}),
    Stdlib::Host         $listen_address = lookup('profile::metamonitoring::deadmanswitchamhook::listen_address', { default_value => '0.0.0.0' }),
    Stdlib::Port         $listen_port    = lookup('profile::metamonitoring::deadmanswitchamhook::listen_port', { default_value => 20666}),
) {

  class { 'metamonitoring::deadmanswitchamhook':
      ensure         => $ensure,
      user           => $user,
      status_dir     => $status_dir,
      log_dir        => $log_dir,
      listen_address => $listen_address,
      listen_port    => $listen_port,
  }

}
