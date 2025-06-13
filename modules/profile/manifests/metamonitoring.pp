# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring(
    String               $group       = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $install_dir = lookup('profile::metamonitoring::install_dir', { default_value => '/usr/local/prometheus-metamonitoring'}),
) {

    user { $group:
        ensure     => 'present',
        shell      => '/usr/sbin/nologin',
        managehome => false,
        system     => true,
    }

    file { $install_dir:
        ensure => 'directory',
        owner  => $group,
        group  => $group,
        mode   => '0770',
    }

    class { 'profile::metamonitoring::deadmanswitchamhook': 
        group       => $group,
        install_dir => $install_dir,
    }

    class { 'profile::metamonitoring::public_endpoint':
        group       => $group,
        install_dir => $install_dir,
    }

}
