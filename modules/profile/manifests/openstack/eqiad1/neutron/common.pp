class profile::openstack::eqiad1::neutron::common(
    $version = lookup('profile::openstack::eqiad1::version'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    $db_pass = lookup('profile::openstack::eqiad1::neutron::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::neutron::db_host'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::neutron::rabbit_pass'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::eqiad1::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::eqiad1::keystone::enforce_new_policy_defaults'),
    $agent_down_time = lookup('profile::openstack::eqiad1::neutron::agent_down_time'),
    $log_agent_heartbeats = lookup('profile::openstack::eqiad1::neutron::log_agent_heartbeats'),
    Stdlib::Port $bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::neutron::common':
        version                     => $version,
        openstack_control_nodes     => $openstack_control_nodes,
        haproxy_nodes               => $haproxy_nodes,
        rabbitmq_nodes              => $rabbitmq_nodes,
        keystone_api_fqdn           => $keystone_api_fqdn,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        region                      => $region,
        dhcp_domain                 => $dhcp_domain,
        ldap_user_pass              => $ldap_user_pass,
        rabbit_pass                 => $rabbit_pass,
        agent_down_time             => $agent_down_time,
        log_agent_heartbeats        => $log_agent_heartbeats,
        bind_port                   => $bind_port,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }
    contain '::profile::openstack::base::neutron::common'
}
