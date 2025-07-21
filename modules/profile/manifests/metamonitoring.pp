# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring(
    Wmflib::Ensure       $ensure      = lookup('profile::metamonitoring::ensure', {default_value => 'present'}),
    String               $group       = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $status_dir  = lookup('profile::metamonitoring::status_dir', { default_value => '/var/lib/o11y-metamonitoring'}),
    Stdlib::Absolutepath $log_dir     = lookup('profile::metamonitoring::log_dir', { default_value => '/var/log/o11y-metamonitoring'}),
) {

    group { $group:
        ensure => $ensure,
        system => true,
    }

    # install dir
    file { '/usr/local/lib/o11y-metamonitoring':
        ensure => stdlib::ensure($ensure, 'directory'),
        group  => $group,
        mode   => '0555',
    }

    file { $log_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
        group  => $group,
        mode   => '0770',
    }

    logrotate::rule { 'o11y-metamonitoring':
        ensure        => $ensure,
        file_glob     => "${log_dir}/*.log",
        frequency     => 'daily',
        rotate        => 5,
        copy_truncate => true,
        missing_ok    => true,
        no_create     => true,
        compress      => true,
    }

    file { $status_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
        group  => $group,
        mode   => '0770',
    }

    include profile::metamonitoring::deadmanswitchamhook
    include profile::metamonitoring::public_endpoint

}
