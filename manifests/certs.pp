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
        command => "/usr/bin/openssl pkcs12 -export -name \"${certalias}\" -passout pass:${defaultpassword} -in /etc/ssl/certs/${certname}.pem -inkey /etc/ssl/private/${certname}.key -out ${location}/${certname}.p12",
        onlyif  => "/usr/bin/test -s /etc/ssl/private/${certname}.key",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/etc/ssl/certs/${certname}.pem"],
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
    $location = '/etc/ssl/certs',
) {
    # chained cert, used when needing to provide
    # an entire certificate chain to a client
    exec { "${name}_create_chained_cert":
        creates => "${location}/${certname}.chained.pem",
        command => "/bin/cat ${certname}.pem ${ca} > ${location}/${certname}.chained.pem",
        cwd     => '/etc/ssl/certs',
        require => [Package['openssl'],
                    File["/etc/ssl/certs/${certname}.pem"],
        ],
    }
    # Fix permissions on the chained file, and make it available as
    file { "${location}/${certname}.chained.pem":
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
        creates => "${location}/${certname}.pem",
        command => "/bin/cat /etc/ssl/certs/${certname}.pem /etc/ssl/private/${certname}.key > ${location}/${certname}.pem",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/etc/ssl/certs/${certname}.pem"],
        ];
    }
    # Fix permissions on the combined file, and make it available as
    # a puppet resource
    file { "${location}/${certname}.pem":
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

    require certificates::packages,
        certificates::rapidssl_ca,
        certificates::rapidssl_ca_2,
        certificates::digicert_ca,
        certificates::wmf_ca
    # Public key
    file { "/etc/ssl/certs/${name}.pem":
        owner  => 'root',
        group  => $group,
        mode   => '0444',
        source => "puppet:///files/ssl/${name}.pem",
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
    # Many services require certificates to be found by a hash in
    # the certs directory
    exec { "${name}_create_hash":
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/${name}.pem).0\" ]",
        command => "/bin/ln -sf /etc/ssl/certs/${name}.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/${name}.pem).0",
        require => [Package['openssl'],
                    File["/etc/ssl/certs/${name}.pem"],
        ],
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
            'unified.wikimedia.org'        => 'DigiCertHighAssuranceCA-3.pem',
            'star.wikimedia.org'           => 'RapidSSL_CA.pem RapidSSL_CA_2.pem GeoTrust_Global_CA.pem',
            'star.wikipedia.org'           => 'DigiCertHighAssuranceCA-3.pem DigiCert_High_Assurance_EV_Root_CA.pem',
            'star.wiktionary.org'          => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikiquote.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikibooks.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikisource.org'          => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikinews.org'            => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikiversity.org'         => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.mediawiki.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikimediafoundation.org' => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wmflabs.org'             => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wmflabs'                 => 'wmf-labs.pem',
            'star.planet.wikimedia.org'    => 'DigiCertHighAssuranceCA-3.pem DigiCert_High_Assurance_EV_Root_CA.pem',
            'star.wmfusercontent.org'      => 'GlobalSign_CA.pem',
            default => 'wmf-ca.pem',
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

class certificates::packages {

    package { [ 'openssl', 'ca-certificates', 'ssl-cert' ]:
        ensure => 'latest',
    }

}

class certificates::star_wmflabs_org {

    install_certificate{ 'star.wmflabs.org': }

}

class certificates::star_wmflabs {

    install_certificate{ 'star.wmflabs': }

}

class certificates::wmf_ca {

    include certificates::packages

    file { '/etc/ssl/certs/wmf-ca.pem':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-ca.pem',
        require => Package['openssl'],
    }

    exec { '/bin/ln -s /etc/ssl/certs/wmf-ca.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/wmf-ca.pem).0':
            unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/wmf-ca.pem).0\" ]",
            require => File['/etc/ssl/certs/wmf-ca.pem'],
    }

}

class certificates::wmf_labs_ca {

    include certificates::packages

    file { '/etc/ssl/certs/wmf-labs.pem':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-labs.pem',
        require => Package['openssl'],
    }

    exec { '/bin/ln -s /etc/ssl/certs/wmf-labs.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/wmf-labs.pem).0':
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/wmf-labs.pem).0\" ]",
        require => File['/etc/ssl/certs/wmf-labs.pem'],
    }

}

class certificates::rapidssl_ca {

    include certificates::packages

    file { '/etc/ssl/certs/RapidSSL_CA.pem':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ssl/RapidSSL_CA.pem',
            require => Package['openssl'],
    }

    exec { '/bin/ln -sf /etc/ssl/certs/RapidSSL_CA.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/RapidSSL_CA.pem).0':
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/RapidSSL_CA.pem).0\" ]",
        require => File['/etc/ssl/certs/RapidSSL_CA.pem'],
    }

}

class certificates::rapidssl_ca_2 {

    include certificates::packages

    file { '/etc/ssl/certs/RapidSSL_CA_2.pem':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.pem',
        require => Package['openssl'],
    }

    exec { '/bin/ln -sf /etc/ssl/certs/RapidSSL_CA_2.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/RapidSSL_CA_2.pem).0':
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/RapidSSL_CA_2.pem).0\" ]",
        require => File['/etc/ssl/certs/RapidSSL_CA_2.pem'],
    }

}

class certificates::digicert_ca {

    include certificates::packages

    file { '/etc/ssl/certs/DigiCertHighAssuranceCA-3.pem':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.pem',
        require => Package['openssl'],
    }

    exec { '/bin/ln -sf /etc/ssl/certs/DigiCertHighAssuranceCA-3.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/DigiCertHighAssuranceCA-3.pem).0':
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/DigiCertHighAssuranceCA-3.pem).0\" ]",
        require => File['/etc/ssl/certs/DigiCertHighAssuranceCA-3.pem'],
    }
}

class certificates::globalsign_ca {

    include certificates::packages

    file { '/etc/ssl/certs/GlobalSign_CA.pem':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/GlobalSign_CA.pem',
        require => Package['openssl'],
    }

    exec { '/bin/ln -sf /etc/ssl/certs/GlobalSign_CA.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/GlobalSign_CA.pem).0':
        unless  => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/GlobalSign_CA.pem).0\" ]",
        require => File['/etc/ssl/certs/GlobalSign_CA.pem'],
    }
}
