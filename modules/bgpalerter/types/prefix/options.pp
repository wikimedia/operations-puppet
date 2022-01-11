type Bgpalerter::Prefix::Options = Struct[{
    monitorASns => Hash[String, Struct[{
        group       => String[1],
        upstreams   => Integer[1],
        downstreams => Integer[1],
    }]]
}]
