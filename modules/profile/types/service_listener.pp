type Profile::Service_listener =  Struct[{
    'name'         => String,
    'port'         => Stdlib::Port::Unprivileged,
    'timeout'      => String,
    'service'      => String,
    'http_host'    => Optional[Stdlib::Fqdn],
    'xfp'          => Optional[Enum['http', 'https']],
    'upstream'     => Optional[Stdlib::Fqdn],
    'retry'        => Optional[Hash],
    'keepalive'    => Optional[String],
    'uses_ingress' => Optional[Boolean],
}]
