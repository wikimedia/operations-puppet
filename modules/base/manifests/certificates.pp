class base::certificates {
    include ::sslcert

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
}
