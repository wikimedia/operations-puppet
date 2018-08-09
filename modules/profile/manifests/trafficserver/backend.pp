class profile::trafficserver::backend (
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3129),
    String $outbound_tls_cipher_suite=hiera('profile::trafficserver::backend::outbound_tls_cipher_suite', ''),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
){
    class { '::trafficserver':
        port                      => $port,
        outbound_tls_cipher_suite => $outbound_tls_cipher_suite,
        mapping_rules             => $mapping_rules,
    }
}
