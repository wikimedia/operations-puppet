# SPDX-License-Identifier: Apache-2.0
class profile::mariadb::dbbackup_metrics {
    ensure_packages(['python3-pymysql'])

    file { '/usr/local/bin/dbbackup_metrics.py':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/mariadb/dbbackup_metrics.py',
        require => Package['python3-pymysql'],
    }

    systemd::timer::job { 'mariadb_dbbackup_metrics':
        ensure             => present,
        description        => 'Collect backup metrics for node_exporter',
        command            => '/usr/local/bin/dbbackup_metrics.py',
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => 'hourly',
        },
        monitoring_enabled => true,
        path_exists        => '/run/mysqld/mysqld.m1.sock',
        require            => File['/usr/local/bin/dbbackup_metrics.py'],
        user               => 'root',
    }
}
