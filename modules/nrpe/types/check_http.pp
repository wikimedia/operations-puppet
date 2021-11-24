# type to validate check_http parameters, not complete
type Nrpe::Check_http = Struct[{
    hostname => Stdlib::Host,
    port     => Optional[Stdlib::Port],
    ssl      => Optional[Boolean],
    sni      => Optional[Boolean],
    expect   => Optional[Array[String[1]]],
    header   => Optional[String[1]],
    string   => Optional[String[1]],
    url      => Optional[Stdlib::Unixpath],
    method   => Optional[Wmflib::HTTP::Method],
    warning  => Optional[Integer[1]],
    critical => Optional[Integer[1]],
    timeout  => Optional[Integer[1]],
}]
