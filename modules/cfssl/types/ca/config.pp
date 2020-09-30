type Cfssl::CA::Config = Struct[{
    'private'   => Stdlib::Unixpath,
    certificate => Stdlib::Unixpath,
    config      => Stdlib::Unixpath,
    nets        => Optional[Array[Stdlib::IP::Address]],
}]
