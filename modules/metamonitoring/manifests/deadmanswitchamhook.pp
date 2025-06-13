# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::deadmanswitchamhook (
    String $group,
    String $install_dir,
    Stdlib::Absolutepath $status_dir,
    Stdlib::Host $listen_address,
    Stdlib::Port $listen_port,
    String $user,
) {
    ensure_packages(['python3-gunicorn', 'python3-flask', 'python3-box', 'python3-prometheus-client'])

    user { $user:
        ensure     => 'present',
        shell      => '/usr/sbin/nologin',
        managehome => false,
        system     => true,
        groups     => $group,
    }

    file { $status_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0770',
    }

    file { "${install_dir}/deadmanswitchamhook.py":
        ensure => file,
        source => 'puppet:///modules/metamonitoring/deadmanswitchamhook.py',
        mode   => '0555',
        notify => Service['deadmanswitchamhook'],
    }

    systemd::service { 'deadmanswitchamhook':
        ensure  => present,
        content => init_template('deadmanswitchamhook', 'systemd'),
        restart => true,
    }
}
