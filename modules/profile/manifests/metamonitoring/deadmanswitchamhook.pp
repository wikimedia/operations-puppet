# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::deadmanswitchamhook (
    String               $group,
    Stdlib::Absolutepath $install_dir,
    Stdlib::Absolutepath $status_dir     = lookup('profile::metamonitoring::deadmanswitchamhook:status_dir', { default_value => '/var/lib/deadmanswitchamhook'}),
    Stdlib::Host         $listen_address = lookup('profile::metamonitoring::deadmanswitchamhook:listen_address', { default_value => '0.0.0.0' }),
    Stdlib::Port         $listen_port    = lookup('profile::metamonitoring::deadmanswitchamhook:listen_port', { default_value => 20666}),
    String               $user           = lookup('profile::metamonitoring::deadmanswitchamhook:user', { default_value => 'deadmanswitchamhook' }),
) {

  class { 'metamonitoring::deadmanswitchamhook':
      group          => $group,
      install_dir    => $install_dir,
      status_dir     => $status_dir,
      listen_address => $listen_address,
      listen_port    => $listen_port,
      user           => $user,
  }

}
