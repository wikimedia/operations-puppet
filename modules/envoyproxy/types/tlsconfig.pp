type Envoyproxy::Tlsconfig = Struct[{
    'server_names'  => Array[Variant[Stdlib::Fqdn, Enum['*']]],
    'certificates'  => Optional[Array[Envoyproxy::Tlscertificate]],
    'upstream_port' => Stdlib::Port,
    'upstream_addr' => Optional[Stdlib::Host],
    'cipher_suites' => Optional[Array[String]],
}]
