# SPDX-License-Identifier: Apache-2.0
class conntrackd (
    String $conntrackd_cfg,
    String $systemd_cfg,
) {
    $packages = [
        'conntrack',
        'conntrackd',
    ]

    package { $packages:
        ensure => present,
    }

    file { '/etc/conntrackd/conntrackd.conf':
        ensure  => present,
        content => $conntrackd_cfg,
        require => Package['conntrackd'],
        notify  => Systemd::Service['conntrackd'],
    }

    systemd::service { 'conntrackd':
        content => $systemd_cfg,
        restart => true,
    }

    # file shipped with the deb package, we don't want it
    file { '/var/log/conntrackd-stats.log':
        ensure => absent,
    }

    logrotate::rule { 'conntrackd':
        ensure        => present,
        file_glob     => '/var/log/conntrackd.log',
        frequency     => 'daily',
        not_if_empty  => true,
        rotate        => 3,
        compress      => true,
        missing_ok    => true,
        copy_truncate => true,
    }
}
