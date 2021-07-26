type Statograph::Metric::Prometheus = Struct[{
    'statuspage_id' => String,
    'query'         => String,
    'prometheus'    => Stdlib::Httpurl,
}]
