class profile::openstack::codfw1dev::neutron::common(
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::neutron::db_host'),
    $version = hiera('profile::openstack::codfw1dev::version'),
    $region = hiera('profile::openstack::codfw1dev::region'),
    $dhcp_domain = hiera('profile::openstack::codfw1dev::nova::dhcp_domain'),
    $db_pass = hiera('profile::openstack::codfw1dev::neutron::db_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::codfw1dev::neutron::rabbit_pass'),
    $agent_down_time = hiera('profile::openstack::codfw1dev::neutron::agent_down_time'),
    $log_agent_heartbeats = hiera('profile::openstack::codfw1dev::neutron::log_agent_heartbeats'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    ) {

    class {'::profile::openstack::base::neutron::common':
        version               => $version,
        openstack_controllers => $openstack_controllers,
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
