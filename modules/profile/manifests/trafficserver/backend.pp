class profile::trafficserver::backend (
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3129),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
){
    class { '::trafficserver':
        port          => $port,
        mapping_rules => $mapping_rules,
    }
}
