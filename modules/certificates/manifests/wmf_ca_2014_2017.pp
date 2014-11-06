class certificates::wmf_ca_2014_2017 {

    include certificates::base
    $ca_name = 'wmf_ca_2014_2017'

    file { "/usr/local/share/ca-certificates/${ca_name}.crt":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///files/ssl/${ca_name}.crt",
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

