type Envoyproxy::Tlsconfig = Struct[{
    'server_names'  => Array[Variant[Stdlib::Fqdn, Enum['*']]],
    'certificates'  => Optional[Array[Envoyproxy::Tlscertificate]],
    'upstream'      => Envoyproxy::Upstream,
    'tlsparams'     => Optional[Envoyproxy::Tlsparams],
}]
