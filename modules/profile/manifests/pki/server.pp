# @summary configure a PKI sevrver
# @param ca_cn The certificate authority CN (Required)
# @param ca_key_content The location of the private key as used by the secret function (Required)
# @param ca_cert_content The location of the public cert as used by the file function (Required)
# @param ca_names The certificate authority names
# @param ca_key_params The CA key algorithm and size
# @param gen_csr if true genrate a CSR.  this is only needed when bootstrapping
# @param profiles a Hash of signing profiles
class profile::pki::server(
    String                       $ca_cn           = lookup('profile::pki::server::ca_cn'),
    String                       $ca_key_content  = lookup('profile::pki::server::ca_key_content'),
    String                       $ca_cert_content = lookup('profile::pki::server::ca_cert_content'),
    Array[Cfssl::Name]           $ca_names        = lookup('profile::pki::server::ca_names'),
    Cfssl::Key                   $ca_key_params   = lookup('profile::pki::server::ca_key_params'),
    Boolean                      $gen_csr         = lookup('profile::pki::server::gen_csr'),
    Hash[String, Cfssl::Profile] $profiles        = lookup('profile::pki::server::profiles'),
) {
    class {'cfssl':
        profiles        => $profiles,
        ca_key_content  => secret($ca_key_content),
        ca_cert_content => file($ca_cert_content),
    }
    if $gen_csr {
        cfssl::csr {$ca_cn:
            key   => $ca_key_params,
            names => $ca_names,
            sign  => false,
        }
    }
}
