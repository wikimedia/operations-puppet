class profile::openstack::labtestn::neutron::common(
    $version = hiera('profile::openstack::labtestn::version'),
    $region = hiera('profile::openstack::labtestn::region'),
    $db_pass = hiera('profile::openstack::labtestn::neutron::db_pass'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $keystone_host = hiera('profile::openstack::labtestn::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::labtestn::neutron::rabbit_pass'),
    $tld = hiera('profile::openstack::labtestn::neutron::tld'),
    $agent_down_time = hiera('profile::openstack::labtestn::neutron::agent_down_time'),
    $log_agent_heartbeats = hiera('profile::openstack::labtestn::neutron::log_agent_heartbeats'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::neutron::common':
        version              => $version,
        nova_controller      => $nova_controller,
        keystone_host        => $keystone_host,
        db_pass              => $db_pass,
        db_host              => $nova_controller,
        region               => $region,
        ldap_user_pass       => $ldap_user_pass,
        rabbit_pass          => $rabbit_pass,
        tld                  => $tld,
        agent_down_time      => $agent_down_time,
        log_agent_heartbeats => $log_agent_heartbeats,
    }
    contain '::profile::openstack::base::neutron::common'
}
