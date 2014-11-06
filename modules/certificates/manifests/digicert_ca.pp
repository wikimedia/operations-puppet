class certificates::digicert_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/DigiCertHighAssuranceCA-3.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

