# The puppet_ca_content variable here is intended to be used temporarily to assist with a puppetmaster
# switch. You can set it at the same time as changing an agent's puppetmaster, obviously using the CA of
# the new puppetmaster, and on the agent's last run with the old puppetmaster, it will replace the CA file
# with the new one. This will make it able to talk to the new puppetmaster on its next run.
# A puppetmaster's CA cert can be found at /var/lib/puppet/server/ssl/certs/ca.pem
class profile::base::certificates (
    Hash              $puppet_ca_content   = lookup('profile::base::certificates::puppet_ca_content'),
    Optional[String]  $puppetmaster_key    = lookup('puppetmaster'),
    Boolean           $include_bundle_jks  = lookup('profile::base::certificates::include_bundle_jks'),
    Boolean           $include_bundle_p12  = lookup('profile::base::certificates::include_bundle_p12'),
    Array[Stdlib::Unixpath] $trusted_certs = lookup('profile::base::certificates::trusted_certs'),
) {
    # Includes internal root CA's e.g.
    # * puppet CA
    # * CFSSL CA
    ensure_packages(['wmf-certificates'])
    include sslcert

    sslcert::ca { 'wmf_ca_2017_2020':
        source  => 'puppet:///modules/base/ca/wmf_ca_2017_2020.crt',
    }
    sslcert::ca { 'RapidSSL_SHA256_CA_-_G3':
        source  => 'puppet:///modules/base/ca/RapidSSL_SHA256_CA_-_G3.crt',
    }
    sslcert::ca { 'DigiCert_High_Assurance_CA-3':
        source  => 'puppet:///modules/base/ca/DigiCert_High_Assurance_CA-3.crt',
    }
    sslcert::ca { 'DigiCert_SHA2_High_Assurance_Server_CA':
        source => 'puppet:///modules/base/ca/DigiCert_SHA2_High_Assurance_Server_CA.crt',
    }
    sslcert::ca { 'DigiCert_TLS_RSA_SHA256_2020_CA1':
        source => 'puppet:///modules/base/ca/DigiCert_TLS_RSA_SHA256_2020_CA1.crt',
    }
    sslcert::ca { 'DigiCert_TLS_Hybrid_ECC_SHA384_2020_CA1':
        source => 'puppet:///modules/base/ca/DigiCert_TLS_Hybrid_ECC_SHA384_2020_CA1.crt',
    }
    sslcert::ca { 'GlobalSign_Organization_Validation_CA_-_SHA256_-_G2':
        source  => 'puppet:///modules/base/ca/GlobalSign_Organization_Validation_CA_-_SHA256_-_G2.crt',
    }
    sslcert::ca { 'GlobalSign_RSA_OV_SSL_CA_2018.crt':
        source  => 'puppet:///modules/base/ca/GlobalSign_RSA_OV_SSL_CA_2018.crt',
    }
    sslcert::ca { 'GlobalSign_ECC_OV_SSL_CA_2018.crt':
        source  => 'puppet:///modules/base/ca/GlobalSign_ECC_OV_SSL_CA_2018.crt',
    }
    # This is a cross-sign for the above GlobalSign_ECC_OV_SSL_CA_2018 to reach
    # the more-widely-known R3 root instead of its default R5 root.
    sslcert::ca { 'GlobalSign_ECC_Root_CA_R5_R3_Cross.crt':
        source  => 'puppet:///modules/base/ca/GlobalSign_ECC_Root_CA_R5_R3_Cross.crt',
    }

    $jks_truststore_path = $include_bundle_jks ? {
        true  => '/etc/ssl/localcerts/wmf_trusted_root_cas.jks',
        false => undef,
    }
    $p12_truststore_path = $include_bundle_p12 ? {
        true  => '/etc/ssl/localcerts/wmf_trusted_root_cas.p12',
        false => undef,
    }

    # The truststore files contain public certificates bundle,
    # we don't really need any password protection.
    # Java truststores for example (.jks) can't be passwordless,
    # so we explicitly set a password to use it in various configs
    # if needed. The default cacert truststore in Debian has the same password.
    $truststore_password = 'changeit'

    class { 'sslcert::trusted_ca':
        trusted_certs       => $trusted_certs,
        jks_truststore_path => $jks_truststore_path,
        p12_truststore_path => $p12_truststore_path,
        truststore_password => $truststore_password,
    }

    if has_key($puppet_ca_content, $puppetmaster_key) {
        exec { 'clear-old-puppet-ssl':
            command     => "/bin/bash -c '/bin/mv /var/lib/puppet/ssl /var/lib/puppet/ssl.\$(/bin/date +%Y-%m-%dT%H:%M)'",
            refreshonly => true,
        }
        sslcert::ca { 'Puppet_Internal_CA':
            content => $puppet_ca_content[$puppetmaster_key],
            notify  => Exec['clear-old-puppet-ssl'],
        }
    } else {
        $puppet_ssl_dir = puppet_ssldir()
        sslcert::ca { 'Puppet_Internal_CA':
            source => "${puppet_ssl_dir}/certs/ca.pem",
        }
    }

    # install all CAs before generating certificates
    Sslcert::Ca <| |> -> Sslcert::Certificate<| |>
}
