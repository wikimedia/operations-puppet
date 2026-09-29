# SPDX-License-Identifier: Apache-2.0
class profile::mediabackup::backup_metrics {
    ensure_packages(['python3-pymysql'])

    $collector = '/usr/local/bin/mediabackup_metrics.py'

    file { $collector:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/mediabackup/mediabackup_metrics.py',
        require => Package['python3-pymysql'],
    }

    systemd::timer::job { 'mediabackup-metrics':
        ensure             => present,
        description        => 'Collect backup metrics for node_exporter',
        command            => $collector,
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => 'hourly',
        },
        monitoring_enabled => true,
        require            => File[$collector],
        user               => 'mediabackup',
    }
}
