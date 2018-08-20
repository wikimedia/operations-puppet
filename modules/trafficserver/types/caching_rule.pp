type Trafficserver::Caching_rule = Struct[{
    'primary_destination' => Enum['dest_domain', 'dest_host', 'dest_ip', 'host_regex', 'url_regex'],
    'value'               => String,
    'action'              => Enum['never-cache', 'ignore-no-cache', 'ignore-client-no-cache', 'ignore-server-no-cache'],
}]
