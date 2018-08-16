type Trafficserver::Storage_element = Struct[{
    'pathname' => Optional[Stdlib::Absolutepath],
    'devname'  => Optional[String],
    'size'     => Variant[Undef, Pattern[/^[0-9]+[KMGT]$/]],
    'volume'   => Optional[Integer],
    'id'       => Optional[String],
}]
