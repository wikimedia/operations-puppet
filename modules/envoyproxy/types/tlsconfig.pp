# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Tlsconfig = Struct[{
    'server_names'   => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn, Enum['*']]],
    'cert_path'     => Optional[Stdlib::Unixpath],
    'key_path'      => Optional[Stdlib::Unixpath],
    'upstream_port' => Stdlib::Port,
    'upstream_addr' => Optional[Stdlib::Host],
    'upstream_tls'   => Optional[Boolean],
    'upstream_sni'   => Optional[String],
    'upstream_trusted_ca' => Optional[Stdlib::UnixPath],
}]
