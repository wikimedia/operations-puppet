define install_certificate(
    $group     = 'ssl-cert',
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

    sslcert::chainedcert { $name:
        group => $group,
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
