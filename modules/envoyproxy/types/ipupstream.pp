type Envoyproxy::Ipupstream = Struct[{
    'port' => Stdlib::Port,
    'addr' => Optional[Stdlib::Host],
}]
