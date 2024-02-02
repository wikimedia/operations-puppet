# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::designate::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    String $openstack_control_node_interface = lookup('profile::openstack::base::neutron::openstack_control_node_interface', {default_value => 'cloud_private_fqdn'}),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::codfw1dev::designate::db_pass'),
    $db_host = lookup('profile::openstack::codfw1dev::designate::db_host'),
    $domain_id_internal_forward = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_forward'),
    $domain_id_internal_forward_legacy = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_reverse = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_reverse'),
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::codfw1dev::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::codfw1dev::designate::db_admin_pass'),
    Array[Hash] $pdns_hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    $osm_host = lookup('profile::openstack::codfw1dev::osm_host'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    Integer $mcrouter_port = lookup('profile::openstack::codfw1dev::designate::mcrouter_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::codfw1dev::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::codfw1dev::keystone::enforce_new_policy_defaults'),
) {

    $designate_hosts = $openstack_control_nodes.map |$node| { $node[$openstack_control_node_interface] }

    class{'::profile::openstack::base::designate::service':
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_fqdn                     => $keystone_fqdn,
        db_pass                           => $db_pass,
        db_host                           => $db_host,
        domain_id_internal_forward        => $domain_id_internal_forward,
        domain_id_internal_forward_legacy => $domain_id_internal_forward_legacy,
        domain_id_internal_reverse        => $domain_id_internal_reverse,
        puppetmaster_hostname             => $puppetmaster_hostname,
        openstack_control_nodes           => $openstack_control_nodes,
        ldap_user_pass                    => $ldap_user_pass,
        pdns_api_key                      => $pdns_api_key,
        db_admin_pass                     => $db_admin_pass,
        pdns_hosts                        => $pdns_hosts,
        rabbitmq_nodes                    => $rabbitmq_nodes,
        rabbit_pass                       => $rabbit_pass,
        osm_host                          => $osm_host,
        region                            => $region,
        mcrouter_port                     => $mcrouter_port,
        haproxy_nodes                     => $haproxy_nodes,
        enforce_policy_scope              => $enforce_policy_scope,
        enforce_new_policy_defaults       => $enforce_new_policy_defaults,
    }
    contain '::profile::openstack::base::designate::service'
}
