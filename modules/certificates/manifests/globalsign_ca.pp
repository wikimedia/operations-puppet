class certificates::globalsign_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/GlobalSign_CA.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/GlobalSign_CA.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}
