type Profile::Service_listener =  Struct[{
    'name'                     => String,
    'port'                     => Stdlib::Port::Unprivileged,
    'timeout'                  => String,
    'idle_timeout'             => Optional[String],
    'service'                  => String,
    'http_host'                => Optional[Stdlib::Fqdn],
    'xfp'                      => Optional[Enum['http', 'https']],
    'upstream'                 => Optional[Stdlib::Fqdn],
    'retry'                    => Optional[Hash],
    'keepalive'                => Optional[String],
    'sets_sni'                 => Optional[Boolean],
    'sni_rewrites_host_header' => Optional[Boolean],
    'tcp_keepalive'            => Optional[Struct[{
        'keepalive_probes'   => Optional[Integer],
        'keepalive_time'     => Optional[Integer],
        'keepalive_interval' => Optional[Integer]
    }]],
    'splits'                   => Optional[Array[Struct[{
        'name'                     => String,
        'host_regex'               => String,
        'service'                  => String,
        'upstream'                 => Stdlib::Fqdn,
        'keepalive'                => Optional[String],
        'sets_sni'                 => Optional[Boolean],
        'sni_rewrites_host_header' => Optional[Boolean],
        'tcp_keepalive'            => Optional[Struct[{
            'keepalive_probes'   => Optional[Integer],
            'keepalive_time'     => Optional[Integer],
            'keepalive_interval' => Optional[Integer]
        }]],
    }]]],
}]
