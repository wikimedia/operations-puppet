# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring(
    String $group = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
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

    include profile::metamonitoring::deadmanswitchamhook
    include profile::metamonitoring::public_endpoint

}
