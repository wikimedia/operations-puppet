# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring(
    Wmflib::Ensure       $ensure      = lookup('profile::metamonitoring::ensure', {default_value => 'present'}),
    String               $user        = lookup('profile::metamonitoring::user', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $status_dir  = lookup('profile::metamonitoring::status_dir', { default_value => '/var/lib/o11y-metamonitoring'}),
    # TODO Remove once cleanup is done
    Stdlib::Absolutepath $log_dir     = lookup('profile::metamonitoring::log_dir', { default_value => '/var/log/o11y-metamonitoring'}),
) {

    systemd::sysuser { $user:
        ensure   => $ensure,
        home_dir => '/usr/local/lib/o11y-metamonitoring',
        shell    => '/bin/bash',
    }

    # install dir
    file { '/usr/local/lib/o11y-metamonitoring':
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => $user,
        group   => $user,
        mode    => '0755',
        require => User[$user],
    }

    # TODO Remove once cleanup is done
    file { $log_dir:
        ensure => 'absent',
        force  => true,
        owner  => $user,
        group  => $user,
        mode   => '0755',
    }

    # TODO Remove once cleanup is done
    logrotate::rule { 'o11y-metamonitoring':
        ensure        => 'absent',
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
        owner  => $user,
        group  => $user,
        mode   => '0755',
    }

    include profile::metamonitoring::deadmanswitchamhook
    include profile::metamonitoring::public_endpoint

}
