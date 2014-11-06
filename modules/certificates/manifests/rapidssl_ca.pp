class certificates::rapidssl_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA.crt':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ssl/RapidSSL_CA.crt',
            require => Package['openssl'],
            notify  => Exec['update-ca-certificates'],
    }
}

