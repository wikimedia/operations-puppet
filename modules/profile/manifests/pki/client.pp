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
    Boolean          $use_stunnel = lookup('profile::pki::client::use_stunnel'),
    String           $auth_key    = lookup('profile::pki::client::auth_key'),
    Stdlib::Unixpath $ca_path     = lookup('profile::pki::client::ca_path'),
    Stdlib::Unixpath $cert_path   = lookup('profile::pki::client::cert_path'),
    Stdlib::Unixpath $key_path    = lookup('profile::pki::client::key_path'),
) {
    if $use_stunnel {
        $signer = 'http://localhost:8888'
        stunnel::daemon {'cfssl':
            ensure       => $ensure,
            accept_port  => 8888,
            connect_host => $signer_host,
            connect_port => $signer_port,
            client       => true,
            verify_chain => true,
            ca_path      => $ca_path,
            cert_path    => $cert_path,
            key_path     => $key_path,
            before       => Class['cfssl::client'],
        }
    } else {
        $signer = "https://${signer_host}:${signer_port}"
    }
    class {'cfssl::client':
        ensure   => $ensure,
        signer   => $signer,
        auth_key => $auth_key,
    }
}
