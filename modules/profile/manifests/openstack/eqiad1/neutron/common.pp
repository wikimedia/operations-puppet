class profile::openstack::eqiad1::neutron::common(
    $version = lookup('profile::openstack::eqiad1::version'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    $db_pass = lookup('profile::openstack::eqiad1::neutron::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::neutron::db_host'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::neutron::rabbit_pass'),
    $agent_down_time = lookup('profile::openstack::eqiad1::neutron::agent_down_time'),
    $log_agent_heartbeats = lookup('profile::openstack::eqiad1::neutron::log_agent_heartbeats'),
    Stdlib::Port $bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::neutron::common':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        rabbitmq_nodes        => $rabbitmq_nodes,
        keystone_api_fqdn     => $keystone_api_fqdn,
        db_pass               => $db_pass,
        db_host               => $db_host,
        region                => $region,
        dhcp_domain           => $dhcp_domain,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        agent_down_time       => $agent_down_time,
        log_agent_heartbeats  => $log_agent_heartbeats,
        bind_port             => $bind_port,
    }
    contain '::profile::openstack::base::neutron::common'
}
