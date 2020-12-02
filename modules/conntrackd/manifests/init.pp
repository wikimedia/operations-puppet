class conntrackd (
    String $conntrackd_cfg,
    String $systemd_cfg,
) {
    package { 'conntrackd':
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
}
