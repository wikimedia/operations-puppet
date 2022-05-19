# SPDX-License-Identifier: Apache-2.0
# @summary TLS configuration for dnsdist's DoH and DoT frontends
#
# @param min_tls_version
#   the minimum version of TLS protocol to support. required.
#
# @param ciphers_tls13
#   TLS ciphers to use for TLSv1.3. optional.
#
# @param ciphers
#   TLS ciphers to use. optional.

type Dnsdist::TLS_config = Struct[{
    min_tls_version => Enum['tls1.2', 'tls1.3'],
    ciphers_tls13   => Optional[Array[String]],
    ciphers         => Optional[Array[String]],
}]
