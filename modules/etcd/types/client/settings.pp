type Etcd::Client::Settings = Struct[{
    username        => Optional[String[1]],
    password        => Optional[String[1]],
    host            => Optional[Stdlib::Host],
    port            => Optional[Stdlib::Port],
    srv_domain      => Optional[Stdlib::Host],
    ca_cert         => Optional[Stdlib::Unixpath],
    protocol        => Optional[Enum['https']],
    allow_reconnect => Optional[Boolean],
}]
