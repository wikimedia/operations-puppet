class profile::openstack::base::neutron::common(
    $version = lookup('profile::openstack::base::version'),
    $region = lookup('profile::openstack::base::region'),
    $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    $db_user = lookup('profile::openstack::base::neutron::db_user'),
    $db_pass = lookup('profile::openstack::base::neutron::db_pass'),
    $db_host = lookup('profile::openstack::base::neutron::db_host'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = lookup('profile::openstack::base::neutron::rabbit_user'),
    $rabbit_pass = lookup('profile::openstack::base::neutron::rabbit_pass'),
    $agent_down_time = lookup('profile::openstack::base::neutron::agent_down_time'),
    $log_agent_heartbeats = lookup('profile::openstack::base::neutron::log_agent_heartbeats'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::neutron::bind_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    ) {

    $keystone_admin_uri = "https://${keystone_api_fqdn}:${auth_port}"
    $keystone_public_uri = "https://${keystone_api_fqdn}:${public_port}"

    class {'::openstack::neutron::common':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        rabbitmq_nodes        => $rabbitmq_nodes,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_api_fqdn     => $keystone_api_fqdn,
        keystone_public_uri   => $keystone_public_uri,
        db_pass               => $db_pass,
        db_user               => $db_user,
        db_host               => $db_host,
        region                => $region,
        dhcp_domain           => $dhcp_domain,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        rabbit_user           => $rabbit_user,
        agent_down_time       => $agent_down_time,
        log_agent_heartbeats  => $log_agent_heartbeats,
        bind_port             => $bind_port,
    }
    contain '::openstack::neutron::common'

    openstack::db::project_grants { 'neutron':
        access_hosts => $openstack_controllers,
        db_name      => 'neutron',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
