class profile::openstack::eqiad1::galera::node(
    Integer             $server_id             = lookup('profile::openstack::eqiad1::galera::server_id'),
    Boolean             $enabled               = lookup('profile::openstack::eqiad1::galera::enabled'),
    Stdlib::Port        $listen_port           = lookup('profile::openstack::eqiad1::galera::listen_port'),
    String              $prometheus_db_pass    = lookup('profile::openstack::eqiad1::galera::prometheus_db_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $haproxy_nodes         = lookup('profile::openstack::eqiad1::haproxy_nodes'),
) {
    class {'::profile::openstack::base::galera::node':
        server_id             => $server_id,
        enabled               => $enabled,
        listen_port           => $listen_port,
        openstack_controllers => $openstack_controllers,
        prometheus_db_pass    => $prometheus_db_pass,
        haproxy_nodes         => $haproxy_nodes,
    }
}
