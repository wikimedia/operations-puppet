class profile::openstack::base::neutron::common(
    $version = hiera('profile::openstack::base::version'),
    $region = hiera('profile::openstack::base::region'),
    $dhcp_domain = hiera('profile::openstack::base::nova::dhcp_domain'),
    $db_user = hiera('profile::openstack::base::neutron::db_user'),
    $db_pass = hiera('profile::openstack::base::neutron::db_pass'),
    $db_host = hiera('profile::openstack::base::neutron::db_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_standby'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = hiera('profile::openstack::base::neutron::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::neutron::rabbit_pass'),
    $tld = hiera('profile::openstack::base::neutron::tld'),
    $agent_down_time = hiera('profile::openstack::base::neutron::agent_down_time'),
    $log_agent_heartbeats = hiera('profile::openstack::base::neutron::log_agent_heartbeats'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::neutron::bind_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    ) {

    $keystone_admin_uri = "http://${keystone_host}:${auth_port}"
    $keystone_public_uri = "http://${keystone_host}:${public_port}"

    class {'::openstack::neutron::common':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        keystone_admin_uri      => $keystone_admin_uri,
        keystone_host           => $keystone_host,
        keystone_public_uri     => $keystone_public_uri,
        db_pass                 => $db_pass,
        db_user                 => $db_user,
        db_host                 => $db_host,
        region                  => $region,
        dhcp_domain             => $dhcp_domain,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_pass             => $rabbit_pass,
        rabbit_user             => $rabbit_user,
        tld                     => $tld,
        agent_down_time         => $agent_down_time,
        log_agent_heartbeats    => $log_agent_heartbeats,
        bind_port               => $bind_port,
    }
    contain '::openstack::neutron::common'
}
