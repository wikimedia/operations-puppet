class profile::openstack::eqiad1::neutron::common(
    $version = hiera('profile::openstack::eqiad1::version'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $db_pass = hiera('profile::openstack::eqiad1::neutron::db_pass'),
    $db_host = hiera('profile::openstack::eqiad1::neutron::db_host'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::eqiad1::neutron::rabbit_pass'),
    $tld = hiera('profile::openstack::eqiad1::neutron::tld'),
    $agent_down_time = hiera('profile::openstack::eqiad1::neutron::agent_down_time'),
    $log_agent_heartbeats = hiera('profile::openstack::eqiad1::neutron::log_agent_heartbeats'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::neutron::common':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        keystone_host           => $keystone_host,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        region                  => $region,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_pass             => $rabbit_pass,
        tld                     => $tld,
        agent_down_time         => $agent_down_time,
        log_agent_heartbeats    => $log_agent_heartbeats,
    }
    contain '::profile::openstack::base::neutron::common'
}
