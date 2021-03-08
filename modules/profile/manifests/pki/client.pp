# @summary configure WMF pki client
# @param ensure whether to ensure the resource
# @param signer_host The signer host
# @param signer_port The signer port
# @param use_stunnel use an stunnel encrypt
# @param auth_key the cfssl sha256 hmax key
class profile::pki::client (
    Wmflib::Ensure       $ensure                 = lookup('profile::pki::client::ensure'),
    Stdlib::Host         $signer_host            = lookup('profile::pki::client::signer_host'),
    Stdlib::Port         $signer_port            = lookup('profile::pki::client::signer_port'),
    Sensitive[String[1]] $auth_key               = lookup('profile::pki::client::auth_key'),
    Boolean              $enable_proxy           = lookup('profile::pki::client::enable_proxy'),
    Stdlib::Unixpath     $mutual_tls_client_cert = lookup('profile::pki::client::mutual_tls_client_cert'),
    Stdlib::Unixpath     $mutual_tls_client_key  = lookup('profile::pki::client::mutual_tls_client_key'),
    Hash                 $certs                  = lookup('profile::pki::client::certs'),
) {
    $signer = "https://${signer_host}:${signer_port}"
    $bundles_source = "http://${signer_host}/bundles"
    class {'cfssl::client':
        ensure                 => $ensure,
        signer                 => $signer,
        bundles_source         => $bundles_source,
        auth_key               => $auth_key,
        enable_proxy           => $enable_proxy,
        mutual_tls_client_cert => $mutual_tls_client_cert,
        mutual_tls_client_key  => $mutual_tls_client_key,

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
