define create_pkcs12(
    $certname   = $name,
    $cert_alias = '',
    $password   = '',
    $user       = 'root',
    $group      = 'ssl-cert',
    $location   = '/etc/ssl/private',
) {

    include passwords::certs

    if ( $cert_alias == '' ) {
        $certalias = $certname
    } else {
        $certalias = $cert_alias
    }

    if ( $password == '' ) {
        $defaultpassword = $passwords::certs::certs_default_pass
    } else {
        $defaultpassword = $password
    }
    # pkcs12 file, used by things like opendj, nss, and tomcat
    exec  { "${name}_create_pkcs12":
        creates => "${location}/${certname}.p12",
        command => "/usr/bin/openssl pkcs12 -export -name \"${certalias}\" -passout pass:${defaultpassword} -in /usr/local/share/ca-certificates/${certname}.crt -inkey /etc/ssl/private/${certname}.key -out ${location}/${certname}.p12",
        onlyif  => "/usr/bin/test -s /etc/ssl/private/${certname}.key",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/usr/local/share/ca-certificates/${certname}.crt"],
        ],
    }
    # Fix permissions on the p12 file, and make it available as
    # a puppet resource
    file { "${location}/${certname}.p12":
        ensure  => 'file',
        mode    => '0440',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_pkcs12"],
    }
}

define create_chained_cert(
    $ca,
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/usr/local/share/ca-certificates',
) {
    # chained cert, used when needing to provide
    # an entire certificate chain to a client
    exec { "${name}_create_chained_cert":
        creates => "${location}/${certname}.chained.crt",
        command => "/bin/cat ${certname}.crt ${ca} > ${location}/${certname}.chained.crt",
        cwd     => '/usr/local/share/ca-certificates',
        require => [Package['openssl'],
                    File["/usr/local/share/ca-certificates/${certname}.crt"],
        ],
    }
    # Fix permissions on the chained file, and make it available as
    file { "${location}/${certname}.chained.crt":
        ensure  => 'file',
        mode    => '0444',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_chained_cert"],
    }
}

define create_combined_cert(
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/etc/ssl/private',
) {
    # combined cert, used by things like lighttp and nginx
    exec { "${name}_create_combined_cert":
        creates => "${location}/${certname}.crt",
        command => "/bin/cat /usr/local/share/ca-certificates/${certname}.crt /etc/ssl/private/${certname}.key > ${location}/${certname}.crt",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/usr/local/share/ca-certificates/${certname}.crt"],
        ];
    }
    # Fix permissions on the combined file, and make it available as
    # a puppet resource
    file { "${location}/${certname}.crt":
        ensure  => 'file',
        mode    => '0440',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_combined_cert"],
    }
}

define install_certificate(
    $group     = 'ssl-cert',
    $ca        = '',
    $privatekey=true,
) {

    require certificates::base,
        certificates::rapidssl_ca,
        certificates::rapidssl_ca_2,
        certificates::digicert_ca,
        certificates::wmf_ca
    # Public key
    file { "/usr/local/share/ca-certificates/${name}.crt":
        owner  => 'root',
        group  => $group,
        mode   => '0444',
        source => "puppet:///files/ssl/${name}.pem",
        notify  => Exec['update-ca-certificates'],
    }


    if ( $privatekey == true ) {
        # Private key
        file { "/etc/ssl/private/${name}.key":
            owner  => 'root',
            group  => $group,
            mode   => '0440',
            source => "puppet:///private/ssl/${name}.key",
        }
    } else {
        # empty Private key
        file { "/etc/ssl/private/${name}.key":
            ensure => 'present',
        }
    }

    create_pkcs12{ $name: }
    create_combined_cert{ $name: }
    if ( $ca ) {
        $cas = $ca
    } else {
        # PEM files should be listed in order:
        # intermediate -> intermediate -> ... -> root
        # If this is out of order either servers will fail to start,
        # or will not properly have SSL enabled.
        $cas = $name ? {
            'unified.wikimedia.org'        => 'DigiCertHighAssuranceCA-3.crt',
            'star.wikimedia.org'           => 'RapidSSL_CA.crt RapidSSL_CA_2.crt GeoTrust_Global_CA.crt',
            'star.wikipedia.org'           => 'DigiCertHighAssuranceCA-3.crt DigiCert_High_Assurance_EV_Root_CA.crt',
            'star.wiktionary.org'          => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikiquote.org'           => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikibooks.org'           => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikisource.org'          => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikinews.org'            => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikiversity.org'         => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.mediawiki.org'           => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wikimediafoundation.org' => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wmflabs.org'             => 'RapidSSL_CA.crt GeoTrust_Global_CA.crt',
            'star.wmflabs'                 => 'wmf-labs.crt',
            'star.planet.wikimedia.org'    => 'DigiCertHighAssuranceCA-3.crt DigiCert_High_Assurance_EV_Root_CA.crt',
            'star.wmfusercontent.org'      => 'GlobalSign_CA.crt',
            default => 'wmf-ca.crt',
        }
    }
    create_chained_cert{ $name:
        ca => $cas,
    }
}

define install_additional_key(
    $key_loc = '',
    $owner   = 'root',
    $group   = 'ssl-cert',
    $mode    = '0440',
) {

    if ( $key_loc ) {
        file { "${key_loc}/${name}.key":
            owner   => $owner,
            group   => $group,
            mode    => $mode,
            source  => "puppet:///private/ssl/${name}.key",
            require => Package['openssl'],
        }
    }
}

class certificates::base {

    package { [ 'openssl', 'ssl-cert' ]:
        ensure => 'latest',
    }

    exec { 'update-ca-certificates':
        command => '/usr/sbin/update-ca-certificates',
        refreshonly => true,
    }

    package { 'ca-certificates':
        ensure => 'latest',
        notify => Exec['update-ca-certificates'],
    }

}

class certificates::star_wmflabs_org {

    install_certificate{ 'star.wmflabs.org': }

}

class certificates::star_wmflabs {

    install_certificate{ 'star.wmflabs': }

}

class certificates::wmf_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-ca.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-ca.pem',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

class certificates::wmf_labs_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-labs.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-labs.pem',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

class certificates::rapidssl_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA.crt':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ssl/RapidSSL_CA.pem',
            require => Package['openssl'],
            notify  => Exec['update-ca-certificates'],
    }
}

class certificates::rapidssl_ca_2 {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA_2.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.pem',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

class certificates::digicert_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/DigiCertHighAssuranceCA-3.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.pem',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

class certificates::globalsign_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/GlobalSign_CA.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/GlobalSign_CA.pem',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}
