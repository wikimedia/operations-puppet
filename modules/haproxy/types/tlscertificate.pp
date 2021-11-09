type Haproxy::Tlscertificate = Struct[{
    'server_names'       => Array[Variant[Wmflib::Host::Wildcard, Stdlib::Fqdn]],
    'cert_paths'         => Array[Stdlib::Unixpath],
    'warning_threshold'  => Optional[Integer[0]],
    'critical_threshold' => Optional[Integer[0]],
}]
