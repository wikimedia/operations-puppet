# == Type: Dnsdist::TLS_config
#
# TLS configuration for dnsdist for DoH/DoT.
#
#  [*min_tls_version*]
#    [string] the minimum version of TLS protocol to support. required.
#
#  [*cert_chain_path*]
#    [path] path to the certificate chain. required.
#
#  [*cert_privkey_path*]
#    [path] path to the certificate private key. required.
#
#  [*ciphers_tls13*]
#    [array] TLS ciphers to use for TLSv1.3. optional.
#
#  [*ciphers*]
#    [array] TLS ciphers to use. optional.

type Dnsdist::TLS_config = Struct[{
    min_tls_version   => Enum['tls1.2', 'tls1.3'],
    cert_chain_path   => Stdlib::Unixpath,
    cert_privkey_path => Stdlib::Unixpath,
    ciphers_tls13     => Optional[Array[String]],
    ciphers           => Optional[Array[String]],
}]
