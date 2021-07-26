type Statograph::Metric::Graphite = Struct[{
    'statuspage_id' => String,
    'query'         => String,
    'graphite'      => Stdlib::Httpurl,
}]
