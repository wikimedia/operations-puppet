# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::deadmanswitchamhook (
    String $group = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $install_dir = lookup('profile::metamonitoring::install_dir', {default_value => '/usr/local/prometheus-metamonitoring'}),
) {

  class { 'metamonitoring::deadmanswitchamhook':
      prometheus_metamonitor_group => $group,
      install_dir                  => $install_dir,
  }

}
