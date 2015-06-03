class base::certificates {
    include ::sslcert

    sslcert::ca { 'wmf-ca':
        source  => 'puppet:///modules/base/ca/wmf-ca.crt',
    }
    sslcert::ca { 'wmf_ca_2014_2017':
        source  => "puppet:///modules/base/ca/wmf_ca_2014_2017.crt",
    }
    sslcert::ca { 'RapidSSL_CA':
        source  => 'puppet:///modules/base/ca/RapidSSL_CA.crt',
    }
    sslcert::ca { 'RapidSSL_SHA256_CA_-_G3':
        source  => 'puppet:///modules/base/ca/RapidSSL_SHA256_CA_-_G3.crt',
    }
    sslcert::ca { 'GeoTrust_Global_CA':
        source  => 'puppet:///modules/base/ca/GeoTrust_Global_CA.crt',
    }
    sslcert::ca { 'DigiCert_High_Assurance_CA-3':
        source  => 'puppet:///modules/base/ca/DigiCert_High_Assurance_CA-3.crt',
    }
    sslcert::ca { 'DigiCert_SHA2_High_Assurance_Server_CA':
        source => 'puppet:///modules/base/ca/DigiCert_SHA2_High_Assurance_Server_CA.crt',
    }
    sslcert::ca { 'GlobalSign_Organization_Validation_CA_-_SHA256_-_G2':
        source  => 'puppet:///modules/base/ca/GlobalSign_Organization_Validation_CA_-_SHA256_-_G2.crt',
    }

    # FIXME: remove after a while
    sslcert::ca { 'GlobalSign_CA':
        ensure  => absent,
        require => Sslcert::Ca['GlobalSign_Organization_Validation_CA_-_SHA256_-_G2'],
    }
    sslcert::ca { 'DigiCertHighAssuranceCA-3':
        ensure  => absent,
        require => Sslcert::Ca['DigiCert_High_Assurance_CA-3'],
    }
    sslcert::ca { 'DigiCertSHA2HighAssuranceServerCA':
        ensure  => absent,
        require => Sslcert::Ca['DigiCert_SHA2_High_Assurance_Server_CA'],
    }
    sslcert::ca { 'RapidSSL_CA_2':
        ensure  => absent,
        require => Sslcert::Ca['GeoTrust_Global_CA'],
    }
}
