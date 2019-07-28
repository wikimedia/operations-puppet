type Envoyproxy::Tlsconfig = Struct[{
    'server_names'  => Array[Variant[Stdlib::Fqdn, Enum['*']]],
    'cert_path'     => Optional[Stdlib::Unixpath],
    'key_path'      => Optional[Stdlib::Unixpath],
    'upstream_port' => Stdlib::Port,
}]
