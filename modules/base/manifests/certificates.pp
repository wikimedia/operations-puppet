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
    sslcert::ca { 'RapidSSL_CA_2':
        source  => 'puppet:///modules/base/ca/RapidSSL_CA_2.crt',
    }
    sslcert::ca { 'RapidSSL_SHA256_CA_-_G3':
        source  => 'puppet:///modules/base/ca/RapidSSL_SHA256_CA_-_G3.crt',
    }
    sslcert::ca { 'DigiCertHighAssuranceCA-3':
        source  => 'puppet:///modules/base/ca/DigiCertHighAssuranceCA-3.crt',
    }
    sslcert::ca { 'DigiCertSHA2HighAssuranceServerCA':
        source => 'puppet:///modules/base/ca/DigiCertSHA2HighAssuranceServerCA.crt',
    }
    sslcert::ca { 'GlobalSign_CA':
        source  => 'puppet:///modules/base/ca/GlobalSign_CA.crt',
    }
}
