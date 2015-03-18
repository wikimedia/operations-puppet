define create_chained_cert(
    $ca,
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/etc/ssl/localcerts',
) {
    # chained cert, used when needing to provide
    # an entire certificate chain to a client
    # NOTE: This is annoying because to work right regardless of whether
    # the root CA comes from the OS or us, we need to use the /etc/ssl/certs/
    # linkfarm so filenames need to use '*.pem'.

    exec { "${name}_create_chained_cert":
        creates => "${location}/${certname}.chained.crt",
        command => "/bin/cat /etc/ssl/localcerts/${certname}.crt ${ca} > ${location}/${certname}.chained.crt",
        cwd     => '/etc/ssl/certs',
        require => [Package['openssl'],
                    File["/etc/ssl/localcerts/${certname}.crt"],
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

define install_certificate(
    $group     = 'ssl-cert',
    $ca        = '',
    $privatekey=true,
) {

    require certificates::base
    require certificates::rapidssl_ca
    require certificates::rapidssl_ca_2
    require certificates::digicert_ca
    require certificates::wmf_ca
    require certificates::wmf_ca_2014_2017
    require certificates::rapidssl_sha256_ca_G3

    sslcert::certificate { $name:
        group  => $group,
        source => "puppet:///files/ssl/${name}.crt",
    }

    if ( $privatekey == true ) {
        Sslcert::Certificate[$name] {
            # private => file("puppet:///private/ssl/${name}.key"), # cf this commit in certificate.pp
            private => "puppet:///private/ssl/${name}.key",
        }
    }

    if ( $ca ) {
        $cas = $ca
    } else {
        # PEM files should be listed in order:
        # intermediate -> intermediate -> ... -> root
        # If this is out of order either servers will fail to start,
        # or will not properly have SSL enabled.
        $cas = $name ? {
            # NOTE: Those use .pem filenames
            /^sni\./                       => 'GlobalSign_CA.pem',
            'uni.wikimedia.org'            => 'GlobalSign_CA.pem',
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

class certificates::base {
    include ::sslcert
}

class certificates::star_wmflabs_org {

    install_certificate{ 'star.wmflabs.org': }

}

class certificates::star_wmflabs {

    install_certificate{ 'star.wmflabs': }

}

# TODO: define this
# old lost CA, need to remove from all over
class certificates::wmf_ca {
    sslcert::ca { 'wmf-ca':
        source  => 'puppet:///files/ssl/wmf-ca.crt',
    }
}

class certificates::wmf_ca_2014_2017 {
    sslcert::ca { 'wmf_ca_2014_2017':
        source  => "puppet:///files/ssl/wmf_ca_2014_2017.crt",
    }
}

class certificates::wmf_labs_ca {
    sslcert::ca { 'wmf-labs':
        source  => 'puppet:///files/ssl/wmf-labs.crt',
    }
}

class certificates::rapidssl_ca {
    sslcert::ca { 'RapidSSL_CA':
        source  => 'puppet:///files/ssl/RapidSSL_CA.crt',
    }
}

class certificates::rapidssl_ca_2 {
    sslcert::ca { 'RapidSSL_CA_2':
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.crt',
    }
}

class certificates::rapidssl_sha256_ca_G3 {
    sslcert::ca { 'RapidSSL_SHA256_CA_-_G3':
        source  => 'puppet:///files/ssl/RapidSSL_SHA256_CA_-_G3.crt',
    }
}

class certificates::digicert_ca {
    sslcert::ca { 'DigiCertHighAssuranceCA-3':
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.crt',
    }
}

class certificates::globalsign_ca {
    sslcert::ca { 'GlobalSign_CA':
        source  => 'puppet:///files/ssl/GlobalSign_CA.crt',
    }
}
