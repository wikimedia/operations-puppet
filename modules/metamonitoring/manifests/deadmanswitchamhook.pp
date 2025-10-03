# SPDX-License-Identifier: Apache-2.0
class metamonitoring::deadmanswitchamhook (
    Wmflib::Ensure $ensure,
    String $user,
    Stdlib::Absolutepath $status_dir,
    Stdlib::Port $listen_port,
) {
    ensure_packages(['python3-flask', 'python3-box', 'python3-prometheus-client'])

    file { "${status_dir}/deadmanswitchamhook":
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $user,
        mode   => '0755',
    }

    file { '/usr/local/lib/o11y-metamonitoring/deadmanswitchamhook.py':
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/metamonitoring/deadmanswitchamhook.py',
        mode   => '0555',
        notify => Service['deadmanswitchamhook'],
    }

    file { '/usr/local/lib/o11y-metamonitoring/deadmanswitchamhook-wsgi.py':
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/metamonitoring/deadmanswitchamhook-wsgi.py',
        mode   => '0555',
        notify => Service['deadmanswitchamhook'],
    }

    file { '/etc/default/metamonitoring_deadmanswitchamhook':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('metamonitoring/metamonitoring_deadmanswitchamhook.env.erb'),
        mode    => '0444',
        notify  => Service['deadmanswitchamhook']
    }

    systemd::service { 'deadmanswitchamhook':
        ensure  => 'absent',
        content => init_template('deadmanswitchamhook', 'systemd'),
        restart => true,
    }

    #service::uwsgi { 'deadmanswitchamhook':
    #    ensure             => $ensure,
    #    port               => $listen_port,
    #    systemd_user       => $user,
    #    systemd_group      => $user,
    #    icinga_check       => false,
    #    add_logging_config => false,
    #    config             => {
    #      'wsgi-file'        => '/usr/local/lib/o11y-metamonitoring/deadmanswitchamhook-wsgi.py',
    #      'chdir'            => '/usr/local/lib/o11y-metamonitoring',
    #      'processes'        => 4,
    #      'log-stdout'       => true,
    #      'catch-exceptions' => true
    #    },
    #}
}
