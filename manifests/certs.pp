define install_certificate(
    $group     = 'ssl-cert',
    $privatekey=true,
) {

    require certificates::base

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

    sslcert::chainedcert { $name:
        group => $group,
    }
}

class certificates::base {
    include ::sslcert

    sslcert::ca { 'wmf-ca':
        source  => 'puppet:///files/ssl/wmf-ca.crt',
    }
    sslcert::ca { 'wmf_ca_2014_2017':
        source  => "puppet:///files/ssl/wmf_ca_2014_2017.crt",
    }
    sslcert::ca { 'RapidSSL_CA':
        source  => 'puppet:///files/ssl/RapidSSL_CA.crt',
    }
    sslcert::ca { 'RapidSSL_CA_2':
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.crt',
    }
    sslcert::ca { 'RapidSSL_SHA256_CA_-_G3':
        source  => 'puppet:///files/ssl/RapidSSL_SHA256_CA_-_G3.crt',
    }
    sslcert::ca { 'DigiCertHighAssuranceCA-3':
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.crt',
    }
    sslcert::ca { 'DigiCertSHA2HighAssuranceServerCA':
        source => 'puppet:///files/ssl/DigiCertSHA2HighAssuranceServerCA.crt',
    }
    sslcert::ca { 'GlobalSign_CA':
        source  => 'puppet:///files/ssl/GlobalSign_CA.crt',
    }
}
