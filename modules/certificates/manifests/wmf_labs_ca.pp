class certificates::wmf_labs_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-labs.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-labs.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

