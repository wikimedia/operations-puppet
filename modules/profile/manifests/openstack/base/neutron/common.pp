# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::common(
    $version = lookup('profile::openstack::base::version'),
    $region = lookup('profile::openstack::base::region'),
    $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    $db_user = lookup('profile::openstack::base::neutron::db_user'),
    $db_pass = lookup('profile::openstack::base::neutron::db_pass'),
    $db_host = lookup('profile::openstack::base::neutron::db_host'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = lookup('profile::openstack::base::neutron::rabbit_user'),
    $rabbit_pass = lookup('profile::openstack::base::neutron::rabbit_pass'),
    $agent_down_time = lookup('profile::openstack::base::neutron::agent_down_time'),
    $log_agent_heartbeats = lookup('profile::openstack::base::neutron::log_agent_heartbeats'),
    Stdlib::Port $bind_port = lookup('profile::openstack::base::neutron::bind_port'),
    Array[String[1]] $type_drivers = lookup('profile::openstack::base::neutron::type_drivers', {default_value => ['flat', 'vlan', 'vxlan']}),
    Array[String[1]] $tenant_network_types = lookup('profile::openstack::base::neutron::tenant_network_types', {default_value => ['vxlan']}),
    Array[String[1]] $mechanism_drivers = lookup('profile::openstack::base::neutron::mechanism_drivers', {default_value => ['openvswitch', 'l2population']}),
    Integer                                              $default_mtu       = lookup('profile::openstack::base::neutron::default_mtu', {default_value => 9000}),
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks = lookup('profile::openstack::base::neutron::physical_interface_mappings'),
) {

    class {'::openstack::neutron::common':
        version              => $version,
        memcached_nodes      => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes       => $rabbitmq_nodes,
        keystone_fqdn        => $keystone_api_fqdn,
        db_pass              => $db_pass,
        db_user              => $db_user,
        db_host              => $db_host,
        region               => $region,
        dhcp_domain          => $dhcp_domain,
        ldap_user_pass       => $ldap_user_pass,
        rabbit_pass          => $rabbit_pass,
        rabbit_user          => $rabbit_user,
        agent_down_time      => $agent_down_time,
        log_agent_heartbeats => $log_agent_heartbeats,
        bind_port            => $bind_port,
        type_drivers         => $type_drivers,
        tenant_network_types => $tenant_network_types,
        mechanism_drivers    => $mechanism_drivers,
        provider_networks    => $provider_networks,
        default_mtu          => $default_mtu,
    }
    contain '::openstack::neutron::common'

    # TODO: move to the service profile
    openstack::db::project_grants { 'neutron':
        access_hosts => $haproxy_nodes,
        db_name      => 'neutron',
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['neutron-common'],
    }
}
