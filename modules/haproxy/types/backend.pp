type Haproxy::Backend = Struct[{
    prefix  => Enum['unix', 'ipv4', 'ipv6'],
    address => Variant[Stdlib::Unixpath, Stdlib::Host],
    port    => Optional[Stdlib::Port],
}]
