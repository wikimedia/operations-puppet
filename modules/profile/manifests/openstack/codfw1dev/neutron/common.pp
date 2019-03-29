class profile::openstack::codfw1dev::neutron::common(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $region = hiera('profile::openstack::codfw1dev::region'),
    $db_pass = hiera('profile::openstack::codfw1dev::neutron::db_pass'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::codfw1dev::neutron::rabbit_pass'),
    $tld = hiera('profile::openstack::codfw1dev::neutron::tld'),
    $agent_down_time = hiera('profile::openstack::codfw1dev::neutron::agent_down_time'),
    $log_agent_heartbeats = hiera('profile::openstack::codfw1dev::neutron::log_agent_heartbeats'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
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
