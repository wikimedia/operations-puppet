# == Type: Dnsdist::TLS_config
#
# TLS configuration for dnsdist's DoH and DoT frontends.
#
#  [*min_tls_version*]
#    [string] the minimum version of TLS protocol to support. required.
#
#  [*ciphers_tls13*]
#    [array] TLS ciphers to use for TLSv1.3. optional.
#
#  [*ciphers*]
#    [array] TLS ciphers to use. optional.

type Dnsdist::TLS_config = Struct[{
    min_tls_version => Enum['tls1.2', 'tls1.3'],
    ciphers_tls13   => Optional[Array[String]],
    ciphers         => Optional[Array[String]],
}]
