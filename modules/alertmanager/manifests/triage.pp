# SPDX-License-Identifier: Apache-2.0
class alertmanager::triage (
    String $prefix = '',
    String $listen_address = 'localhost:8295',
) {
    ensure_packages(['alerts-triage'])

    profile::auto_restarts::service { 'alerts-triage': }

    systemd::service { 'alerts-triage':
        ensure   => present,
        content  => init_template('alerts-triage', 'systemd_override'),
        override => true,
        restart  => true,
    }

    file { '/etc/alerts-triage.yml':
        ensure    => present,
        owner     => 'alerts-triage',
        group     => 'root',
        mode      => '0440',
        content   => template('alertmanager/alerts-triage.yml.erb'),
        notify    => Service['alerts-triage'],
        show_diff => false,
    }
}
