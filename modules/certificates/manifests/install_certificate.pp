define install_certificate(
    $group     = 'ssl-cert',
    $ca        = '',
    $privatekey=true,
) {

    require certificates::base,
        certificates::rapidssl_ca,
        certificates::rapidssl_ca_2,
        certificates::digicert_ca,
        certificates::wmf_ca,
        certificates::wmf_ca_2014_2017

    # Public key
    file { "/etc/ssl/localcerts/${name}.crt":
        owner   => 'root',
        group   => $group,
        mode    => '0444',
        source  => "puppet:///files/ssl/${name}.crt",
        require => File['/etc/ssl/localcerts'],
    }

    # TODO: Remove once nothing references this anymore
    file { "/etc/ssl/certs/${name}.pem":
        ensure  => link,
        target  => "/etc/ssl/localcerts/${name}.crt",
        require => File["/etc/ssl/localcerts/${name}.crt"],
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
            # NOTE: Those use .pem filenames
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
            'sni.wikimedia.org'            => 'GlobalSign_CA.pem',
            default => 'wmf-ca.pem',
        }
    }
    create_chained_cert{ $name:
        ca => $cas,
    }
}

