# @summary configure a PKI sevrver
# @param ca_key_content The location of the private key as used by the secret function (Required)
# @param ca_cert_content The location of the public cert as used by the file function (Required)
# @param names The certificate authority names used for intermediates
# @param key_params The key algorithm and size used for intermediates
# @param gen_csr if true genrate a CSR.  this is only needed when bootstrapping
# @param profiles a Hash of signing profiles
# @param intermediates a list of intermediate CN's to create
class profile::pki::server(
    String                        $vhost           = lookup('profile::pki::server::vhost'),
    String                        $ocsp_vhost      = lookup('profile::pki::server::ocsp_vhost'),
    String                        $ca_key_content  = lookup('profile::pki::server::ca_key_content'),
    String                        $ca_cert_content = lookup('profile::pki::server::ca_cert_content'),
    Array[Cfssl::Name]            $names           = lookup('profile::pki::server::names'),
    Cfssl::Key                    $key_params      = lookup('profile::pki::server::key_params'),
    Boolean                       $gen_csr         = lookup('profile::pki::server::gen_csr'),
    Hash[String, Cfssl::Profile]  $profiles        = lookup('profile::pki::server::profiles'),
    Hash[String, Cfssl::Auth_key] $auth_keys       = lookup('profile::pki::server::auth_keys'),
    Array[String]                 $intermediates   = lookup('profile::pki::server::intermediates'),
) {
    $crl_url = "http://${vhost}/crl"
    $ocsp_url = "http://${ocsp_vhost}"
    class {'cfssl':
        profiles        => $profiles,
        ca_key_content  => secret($ca_key_content),
        ca_cert_content => file($ca_cert_content),
        ocsp_cert_path  => '/etc/cfssl/internal/ocsp/OCSP_signer.pem',
        ocsp_key_path   => '/etc/cfssl/internal/ocsp/OCSP_signer-key.pem',
        auth_keys       => $auth_keys,
        crl_url         => $crl_url,
        ocsp_url        => $ocsp_url,
    }
    cfssl::csr {'OCSP signer':
        key     => $key_params,
        names   => $names,
        profile => 'ocsp',
    }
    $intermediates.each |$intermediate| {
        cfssl::csr {$intermediate:
            key     => $key_params,
            names   => $names,
            profile => 'intermediate'
        }
    }
    class { 'sslcert::dhparam': }
    class {'httpd':
        modules => ['proxy', 'proxy_http', 'ssl']
    }
    # create variables used in vhost
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    $cfssl_backend = "http://${cfssl::host}:${cfssl::port}/"
    httpd::site {$vhost:
        content => template('profile/pki/cfssl_vhost.conf.erb')
    }
    $ocsp_backend  = "http://${cfssl::host}:${cfssl::ocsp_port}/"
    httpd::site {$ocsp_vhost:
        content => template('profile/pki/ocsp_vhost.conf.erb')
    }
}
