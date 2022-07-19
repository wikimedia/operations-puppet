class profile::openstack::codfw1dev::neutron::common(
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::neutron::db_host'),
    $version = lookup('profile::openstack::codfw1dev::version'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain'),
    $db_pass = lookup('profile::openstack::codfw1dev::neutron::db_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    $rabbit_pass = lookup('profile::openstack::codfw1dev::neutron::rabbit_pass'),
    $agent_down_time = lookup('profile::openstack::codfw1dev::neutron::agent_down_time'),
    $log_agent_heartbeats = lookup('profile::openstack::codfw1dev::neutron::log_agent_heartbeats'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    ) {

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
