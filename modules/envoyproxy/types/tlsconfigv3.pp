type Envoyproxy::TlsconfigV3 = Struct[{
    'server_names'  => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn, Enum['*']]],
    'certificates'  => Optional[Array[Envoyproxy::Tlscertificate]],
    'upstream_port' => Stdlib::Port,
    'upstream_addr' => Optional[Stdlib::Host],
    'cipher_suites' => Optional[Array[String]],
}]
