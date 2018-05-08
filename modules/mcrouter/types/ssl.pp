type Mcrouter::Ssl = Variant[Undef, Struct[{
    'port' => Wmflib::IpPort,
    'ca_cert' => Stdlib::Unixpath,
    'cert' => Stdlib::Unixpath,
    'key'  => Stdlib::Unixpath
}]]
