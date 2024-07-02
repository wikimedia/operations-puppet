class profile::toolforge::elasticsearch::keepalived(
    Elasticsearch::InstanceParams $elastic_settings = lookup('profile::elasticsearch::common_settings'),
    Integer $host_priority = lookup('profile::toolforge::elasticsearch::keepalived::host_priority'),
    Stdlib::IP::Address $vip = lookup('profile::toolforge::elasticsearch::keepalived::vip'),
    String $auth_pass = lookup('profile::toolforge::elasticsearch::keepalived::password'),
    String $keepalived_interface = lookup('profile::toolforge::elasticsearch::keepalived::interface'),
) {
    $peers = delete($elastic_settings['cluster_hosts'], $::fqdn)

    class { 'keepalived':
        auth_pass         => $auth_pass,
        default_state     => 'BACKUP',
        interface         => $keepalived_interface,
        peers             => $peers,
        priority          => $host_priority,
        vips              => [$vip],
        virtual_router_id => 51,
    }
}
