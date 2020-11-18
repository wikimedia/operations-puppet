type Cfssl::CA::Config = Struct[{
    'private'   => Stdlib::Unixpath,
    certificate => Stdlib::Unixpath,
    config      => Stdlib::Unixpath,
    dbconfig    => Optional[Stdlib::Unixpath],
    nets        => Optional[Array[Stdlib::IP::Address]],
}]
