# == Type: Dnsdist::TLS_common
#
# Common TLS configuration for dnsdist's DoH and DoT frontends.
#
#  [*cert_chain_path*]
#    [path] path to the certificate chain. required.
#
#  [*cert_privkey_path*]
#    [path] path to the certificate private key. required.

type Dnsdist::TLS_common = Struct[{
    cert_chain_path   => Stdlib::Unixpath,
    cert_privkey_path => Stdlib::Unixpath,
}]
