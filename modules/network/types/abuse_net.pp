type Network::Abuse_net = Struct[{
    context  => Array[Network::Context],
    networks => Array[Stdlib::IP::Address],
    comment  => Optional[String[1]],
}]
