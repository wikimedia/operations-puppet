# SPDX-License-Identifier: Apache-2.0
# @summary configures the natlog utility
class natlog (
    Logrotate::Frequency         $logrotate_frequency = 'daily',
    Integer[1]                   $logrotate_days      = 4,
) {
    package { 'natlog':
        ensure => present,
    }

    systemd::tmpfile { 'natlog':
        content => 'd /var/log/natlog/ 0755 root adm -',
    }

    $rotate = $logrotate_frequency ? {
        'hourly' => $logrotate_days * 24,
        default  => $logrotate_days,
    }

    logrotate::rule { 'natlog':
        ensure       => present,
        file_glob    => '/var/log/natlog/natlog.log',
        frequency    => $logrotate_frequency,
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => $rotate,
        post_rotate  => ['/usr/lib/rsyslog/rsyslog-rotate'],
    }

    rsyslog::conf { 'natlog':
        source   => 'puppet:///modules/natlog/rsyslog.conf',
        priority => 20,
        require  => Systemd::Tmpfile['natlog'],
    }

    service { 'natlog':
        ensure  => running,
        enable  => true,
        require => [Package['natlog'], Rsyslog::Conf['natlog']],
    }
}
