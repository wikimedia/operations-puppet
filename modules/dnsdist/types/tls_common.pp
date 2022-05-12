# @summary common TLS configuration for dnsdist's DoH and DoT frontends
#
# @param cert_chain_path
#   path to the certificate chain. required.
#
# @param cert_privkey_path
#   path to the certificate private key. required.
#
# @param ocsp_response_path
#   path to the OCSP response file. optional.

type Dnsdist::TLS_common = Struct[{
    cert_chain_path    => Stdlib::Unixpath,
    cert_privkey_path  => Stdlib::Unixpath,
    ocsp_response_path => Optional[Stdlib::Unixpath],
}]
