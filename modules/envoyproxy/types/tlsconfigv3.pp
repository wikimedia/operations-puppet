type Envoyproxy::TlsconfigV3 = Struct[{
    'server_names'  => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn, Enum['*']]],
    'certificates'   => Optional[Array[Envoyproxy::Tlscertificate]],
    'upstream'       => Envoyproxy::Upstream,
    'tlsparams'      => Optional[Envoyproxy::Tlsparams],
    'alpn_protocols' => Optional[Envoyproxy::Alpn],
}]
