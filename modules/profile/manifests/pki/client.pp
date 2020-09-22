# @summary configure WMF pki client
# @param ensure whether to ensure the resource
# @param signer_host The signer host
# @param signer_port The signer port
# @param use_stunnel use an stunnel encrypt
# @param auth_key the cfssl sha256 hmax key
# @param ca_path the CAFile to use for stunnle
# @param cert_path the certificate file to use for stunnle
# @param key_path the private key file to use for stunnle
class profile::pki::client (
    Wmflib::Ensure   $ensure      = lookup('profile::pki::client::ensure'),
    Stdlib::Host     $signer_host = lookup('profile::pki::client::signer_host'),
    Stdlib::Port     $signer_port = lookup('profile::pki::client::signer_port'),
    String           $auth_key    = lookup('profile::pki::client::auth_key'),
    Stdlib::Unixpath $ca_path     = lookup('profile::pki::client::ca_path'),
    Stdlib::Unixpath $cert_path   = lookup('profile::pki::client::cert_path'),
    Stdlib::Unixpath $key_path    = lookup('profile::pki::client::key_path'),
    Hash             $certs       = lookup('profile::pki::client::certs')
) {
    $signer = "https://${signer_host}:${signer_port}"
    class {'cfssl::client':
        ensure   => $ensure,
        signer   => $signer,
        auth_key => $auth_key,
    }
    $certs.each |$title, $cert| {
        cfssl::cert{$title:
            signer_config => {'config_file' => $cfssl::client::conf_file},
            tls_cert      => $facts['puppet_config']['hostcert'],
            tls_key       => $facts['puppet_config']['hostprivkey'],
            *             => $cert,
        }
    }
}
