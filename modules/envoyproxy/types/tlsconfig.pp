# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Tlsconfig = Struct[{
    'server_names'   => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn, Enum['*']]],
    'certificates'   => Optional[Array[Envoyproxy::Tlscertificate]],
    'upstream'       => Envoyproxy::Upstream,
    'upstream_tls'   => Optional[Boolean],
    'upstream_sni'   => Optional[String],
    'upstream_trusted_ca' => Optional[Stdlib::UnixPath],
    'tlsparams'      => Optional[Envoyproxy::Tlsparams],
    'alpn_protocols' => Optional[Envoyproxy::Alpn],
}]
