# SPDX-License-Identifier: Apache-2.0
# @summary configures the natlog utility
class natlog (
    Stdlib::Unixpath             $base_path            = '/srv/natlog',
    Logrotate::Frequency         $logrotate_frequency = 'daily',
    Integer[1]                   $logrotate_days      = 4,
) {
    package { 'natlog':
        ensure => present,
    }

    systemd::tmpfile { 'natlog':
        content => "d ${base_path}/ 0755 root adm -",
    }

    $rotate = $logrotate_frequency ? {
        'hourly' => $logrotate_days * 24,
        default  => $logrotate_days,
    }

    logrotate::rule { 'natlog':
        ensure       => present,
        file_glob    => "${base_path}/natlog.log",
        frequency    => $logrotate_frequency,
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => $rotate,
        post_rotate  => ['/usr/lib/rsyslog/rsyslog-rotate'],
    }

    rsyslog::conf { 'natlog':
        content  => template('natlog/rsyslog.conf.erb'),
        priority => 20,
        require  => Systemd::Tmpfile['natlog'],
    }

    if debian::codename::eq('bullseye') {
        # This is no longer required in bookworm and newer.
        file_line { 'natlog_start':
            ensure => present,
            path   => '/etc/default/natlog',
            line   => 'START=yes',
            match  => '^START',
            notify => Service['natlog'],
        }
    }

    service { 'natlog':
        ensure  => running,
        enable  => true,
        require => [Package['natlog'], Rsyslog::Conf['natlog']],
    }
}
