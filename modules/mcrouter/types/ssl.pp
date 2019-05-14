type Mcrouter::Ssl = Variant[Undef, Struct[{
    'port' => Stdlib::Port,
    'ca_cert' => Stdlib::Unixpath,
    'cert' => Stdlib::Unixpath,
    'key'  => Stdlib::Unixpath
}]]
