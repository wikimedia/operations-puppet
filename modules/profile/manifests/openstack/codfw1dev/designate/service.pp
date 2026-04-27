# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::designate::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::codfw1dev::designate::db_pass'),
    $db_host = lookup('profile::openstack::codfw1dev::designate::db_host'),
    String[1] $domain_id_internal_forward = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_forward'),
    String[1] $domain_id_internal_reverse_v4 = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_reverse_v4'),
    String[1] $domain_id_internal_reverse_v6 = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_reverse_v6'),
    String[1] $enabled_notification_handlers = lookup('profile::openstack::codfw1dev::designate::enabled_notification_handlers'),
    String[1] $base_domain_name = lookup('profile::openstack::codfw1dev::designate::base_domain_name'),
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::designate::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::codfw1dev::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::codfw1dev::designate::db_admin_pass'),
    Array[Profile::Openstack::Pdns::Host] $pdns_hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    $rabbit_pass = lookup('profile::openstack::codfw1dev::designate::rabbit_pass'),
    $osm_host = lookup('profile::openstack::codfw1dev::osm_host'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
) {

    $designate_hosts = $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] }

    class{'::profile::openstack::base::designate::service':
        version                       => $version,
        designate_hosts               => $designate_hosts,
        keystone_fqdn                 => $keystone_fqdn,
        db_pass                       => $db_pass,
        db_host                       => $db_host,
        domain_id_internal_forward    => $domain_id_internal_forward,
        domain_id_internal_reverse_v4 => $domain_id_internal_reverse_v4,
        domain_id_internal_reverse_v6 => $domain_id_internal_reverse_v6,
        enabled_notification_handlers => $enabled_notification_handlers,
        base_domain_name              => $base_domain_name,
        puppetmaster_hostname         => $puppetmaster_hostname,
        openstack_control_nodes       => $openstack_control_nodes,
        ldap_user_pass                => $ldap_user_pass,
        pdns_api_key                  => $pdns_api_key,
        db_admin_pass                 => $db_admin_pass,
        pdns_hosts                    => $pdns_hosts,
        rabbitmq_nodes                => $rabbitmq_nodes,
        rabbit_pass                   => $rabbit_pass,
        osm_host                      => $osm_host,
        region                        => $region,
        haproxy_nodes                 => $haproxy_nodes,
        zookeeper_cluster_name        => 'designate_codfw1dev',
    }
    contain '::profile::openstack::base::designate::service'
}
