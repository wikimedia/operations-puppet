type Trafficserver::Mapping_rule = Struct[{
    'type' => Enum['map', 'regex_map', 'map_with_recv_port', 'regex_map_with_recv_port', 'map_with_referer', 'reverse_map', 'redirect', 'regex_redirect', 'redirect_temporary', 'regex_redirect_temporary'],
    'target' => String,
    'replacement' => String,
    'params' => Optional[Array[String]],
}]
