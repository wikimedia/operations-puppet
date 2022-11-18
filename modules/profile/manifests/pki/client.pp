# SPDX-License-Identifier: Apache-2.0
# @summary configure WMF pki client
# @param ensure whether to ensure the resource
# @param signer_host The signer host
# @param signer_port The signer port
# @param auth_key the cfssl sha256 hmax key
# @param enable_proxy if tru start the proxy service
# @param listen_addr for the proxy service
# @param listen_port for the proxy service
# @param bundles_source puppet source location of intermidate certificates
# @param root_ca_cn cn of the root ca
# @param root_ca_source puppet source location of root ca
# @param mutual_tls_client_cert location of client auth tls cert
# @param mutual_tls_client_key location of client auth tls key
# @param tls_remote_ca location of ca bundle for pki service
# @param tls_remote_ca_source puppet source for tls_remote_ca
# @param certs a hash of certs to create
class profile::pki::client (
    Wmflib::Ensure               $ensure                 = lookup('profile::pki::client::ensure'),
    Stdlib::Host                 $signer_host            = lookup('profile::pki::client::signer_host'),
    Stdlib::Port                 $signer_port            = lookup('profile::pki::client::signer_port'),
    Sensitive[String[1]]         $auth_key               = lookup('profile::pki::client::auth_key'),
    Boolean                      $enable_proxy           = lookup('profile::pki::client::enable_proxy'),
    Stdlib::IP::Address          $listen_addr            = lookup('profile::pki::client::listen_addr'),
    Stdlib::Port                 $listen_port            = lookup('profile::pki::client::listen_port'),
    Stdlib::Filesource           $bundles_source         = lookup('profile::pki::client::bundles_source'),
    Cfssl::Ca_name               $root_ca_cn             = lookup('profile::pki::client::root_ca_cn'),
    Optional[Stdlib::Filesource] $root_ca_source         = lookup('profile::pki::client::root_ca_source'),
    Optional[Stdlib::Unixpath]   $mutual_tls_client_cert = lookup('profile::pki::client::mutual_tls_client_cert'),
    Optional[Stdlib::Unixpath]   $mutual_tls_client_key  = lookup('profile::pki::client::mutual_tls_client_key'),
    Optional[Stdlib::Unixpath]   $tls_remote_ca          = lookup('profile::pki::client::tls_remote_ca'),
    Optional[Stdlib::Filesource] $tls_remote_ca_source   = lookup('profile::pki::client::tls_remote_ca_source'),
    Hash                         $certs                  = lookup('profile::pki::client::certs'),
) {
    $signer = "https://${signer_host}:${signer_port}"
    if $root_ca_source {
        file { "/etc/ssl/certs/${root_ca_cn}.pem":
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => $root_ca_source,
        }
    }
    if $tls_remote_ca_source {
        if $tls_remote_ca == $facts['puppet_config']['localcacert'] {
            fail('When setting \$tls_remote_ca_source you must change \$tls_remote_ca')
        }
        file{$tls_remote_ca:
            ensure => stdlib::ensure($ensure, file),
            owner  => 'root',
            group  => 'root',
            mode   => '0440',
            source => $tls_remote_ca_source,
        }
    }
    class {'cfssl::client':
        ensure                 => $ensure,
        signer                 => $signer,
        bundles_source         => $bundles_source,
        auth_key               => $auth_key,
        enable_proxy           => $enable_proxy,
        listen_addr            => $listen_addr,
        listen_port            => $listen_port,
        mutual_tls_client_cert => $mutual_tls_client_cert,
        mutual_tls_client_key  => $mutual_tls_client_key,
        tls_remote_ca          => $tls_remote_ca,

    }
    $certs.each |$title, $cert| {
        cfssl::cert{$title:
            ensure => $ensure,
            *      => $cert,
        }
    }
}
