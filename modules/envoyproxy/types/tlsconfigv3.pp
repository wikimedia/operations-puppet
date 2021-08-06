type Envoyproxy::TlsconfigV3 = Struct[{
    'server_names'  => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn, Enum['*']]],
    'cert_path'     => Optional[Stdlib::Unixpath],
    'key_path'      => Optional[Stdlib::Unixpath],
    'ocsp_path'     => Optional[Stdlib::Unixpath],
    'upstream_port' => Stdlib::Port,
    'upstream_addr' => Optional[Stdlib::Host],
}]
