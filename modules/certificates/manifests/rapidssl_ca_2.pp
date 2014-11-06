class certificates::rapidssl_ca_2 {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA_2.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

