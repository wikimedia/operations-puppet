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
    String                        $ca_key_content  = lookup('profile::pki::server::ca_key_content'),
    String                        $ca_cert_content = lookup('profile::pki::server::ca_cert_content'),
    Array[Cfssl::Name]            $names           = lookup('profile::pki::server::names'),
    Cfssl::Key                    $key_params      = lookup('profile::pki::server::key_params'),
    Boolean                       $gen_csr         = lookup('profile::pki::server::gen_csr'),
    Hash[String, Cfssl::Profile]  $profiles        = lookup('profile::pki::server::profiles'),
    Hash[String, Cfssl::Auth_key] $auth_keys       = lookup('profile::pki::server::auth_keys'),
    Hash[String, Hash]            $intermediates   = lookup('profile::pki::server::intermediates'),
) {
    $crl_url = "http://${vhost}/crl"
    $ocsp_url = "http://${vhost}/ocsp"
    class {'cfssl': }
    cfssl::signer {'WMF_root_CA':
        profiles         => $profiles,
        ca_key_content   => secret($ca_key_content),
        ca_cert_content  => file($ca_cert_content),
        auth_keys        => $auth_keys,
        default_crl_url  => $crl_url,
        default_ocsp_url => $ocsp_url,
    }
    $signers = $intermediates.reduce({}) |$memo, $value| {
        $intermediate = $value[0]
        $config = $value[1]
        $safe_title = $intermediate.regsubst('\W', '_', 'G')
        if 'private' in $config and 'certificate' in $config {
            $ca_key_file = $config['private']
            $ca_file = $config['certificate']
        } else {
            cfssl::cert{$intermediate:
                key           => $key_params,
                names         => $names,
                signer_config => {'config_dir' => "${cfssl::signer_dir}/WMF_root_CA"},
                profile       => 'intermediate',
                require       => Cfssl::Signer['WMF_root_CA'],
            }
            $ca_key_file = "${cfssl::ssl_dir}/${safe_title}/${safe_title}-key.pem"
            $ca_file = "${cfssl::ssl_dir}/${safe_title}/${safe_title}.pem"
        }
        cfssl::signer {$intermediate:
            profiles         => $profiles,
            ca_key_file      => $ca_key_file,
            ca_file          => $ca_file,
            ca_bundle_file   => "${cfssl::signer_dir}/WMF_root_CA/ca/ca.pem",
            auth_keys        => $auth_keys,
            default_crl_url  => $crl_url,
            default_ocsp_url => $ocsp_url,
        }
        $memo + {
            $safe_title => {
                'private'     => $ca_key_file,
                'certificate' => $ca_file,
                'config'      => "${cfssl::signer_dir}/${safe_title}/cfssl.conf",
                'dbconfig'    => "${cfssl::signer_dir}/${safe_title}/db.conf",
                'nets'        => $config['nets'],
            }
        }
    }
    class {'cfssl::multirootca':
        tls_cert => $facts['puppet_config']['hostcert'],
        tls_key  => $facts['puppet_config']['hostprivkey'],
        signers  => $signers,
    }
}
