# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::deadmanswitchamhook (
    String $prometheus_metamonitor_group,
    String $install_dir,
    Stdlib::Absolutepath $status_dir = '/var/lib/deadmanswitchamhook',
    Stdlib::Host $listen_address = '0.0.0.0',
    Stdlib::Port $listen_port = 20666,
    String $user = 'deadmanswitchamhook',
) {
    ensure_packages(['python3-gunicorn', 'python3-flask', 'python3-box', 'python3-prometheus-client'])

    user { $user:
        ensure     => 'present',
        shell      => '/usr/sbin/nologin',
        managehome => false,
        system     => true,
        groups     => $prometheus_metamonitor_group,
    }

    file { $status_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $prometheus_metamonitor_group,
        mode   => '0770',
    }

    file { "${install_dir}/deadmanswitchamhook.py":
        ensure => file,
        source => 'puppet:///modules/metamonitoring/deadmanswitchamhook.py',
        mode   => '0555',
    }

    systemd::service { 'deadmanswitchamhook':
        ensure  => present,
        content => init_template('deadmanswitchamhook', 'systemd'),
        restart => true,
    }
}
