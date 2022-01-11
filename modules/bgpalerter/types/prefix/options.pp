type Bgpalerter::Prefix::Options = Struct[{
    monitorASns => Hash[String, Struct[{
        group       => String[1],
        upstreams   => Array[Integer[1]],
        downstreams => Array[Integer[1]],
    }]]
}]
