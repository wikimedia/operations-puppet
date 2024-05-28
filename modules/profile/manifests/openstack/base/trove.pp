# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::trove(
    String                        $version                     = lookup('profile::openstack::base::version'),
    Integer                       $workers                     = lookup('profile::openstack::base::trove::workers'),
    Array[OpenStack::ControlNode] $openstack_control_nodes     = lookup('profile::openstack::base::openstack_control_nodes'),
    Array[Stdlib::Fqdn]           $rabbitmq_nodes              = lookup('profile::openstack::base::rabbitmq_nodes'),
    String                        $db_user                     = lookup('profile::openstack::base::trove::db_user'),
    String                        $db_pass                     = lookup('profile::openstack::base::trove::db_pass'),
    String                        $db_name                     = lookup('profile::openstack::base::trove::db_name'),
    Stdlib::Fqdn                  $db_host                     = lookup('profile::openstack::base::trove::db_host'),
    String                        $ldap_user_pass              = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn                  $keystone_fqdn               = lookup('profile::openstack::base::keystone_api_fqdn'),
    String                        $region                      = lookup('profile::openstack::base::region'),
    Stdlib::Port                  $api_bind_port               = lookup('profile::openstack::base::trove::api_bind_port'),
    String                        $rabbit_user                 = lookup('profile::openstack::base::nova::rabbit_user'),
    String                        $rabbit_pass                 = lookup('profile::openstack::base::nova::rabbit_pass'),
    Boolean                       $enforce_policy_scope        = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean                       $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    String                        $trove_guest_rabbit_user     = lookup('profile::openstack::base::trove::trove_guest_rabbit_user'),
    String                        $trove_guest_rabbit_pass     = lookup('profile::openstack::base::trove::trove_guest_rabbit_pass'),
    String                        $trove_service_user_pass     = lookup('profile::openstack::base::trove::trove_user_pass'),
    String                        $trove_quay_user             = lookup('profile::openstack::base::trove::quay_user'),
    String                        $trove_quay_pass             = lookup('profile::openstack::base::trove::quay_pass'),
    String                        $trove_dns_zone              = lookup('profile::openstack::base::trove::dns_zone'),
    String                        $trove_dns_zone_id           = lookup('profile::openstack::base::trove::dns_zone_id'),
    Array[Stdlib::Fqdn]           $haproxy_nodes               = lookup('profile::openstack::base::haproxy_nodes'),
) {

    $designate_internal_uri = "https://${keystone_fqdn}:29001"

    class { '::openstack::trove::service':
        version                     => $version,
        workers                     => $workers,
        memcached_nodes             => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes              => $rabbitmq_nodes,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        ldap_user_pass              => $ldap_user_pass,
        keystone_fqdn               => $keystone_fqdn,
        designate_internal_uri      => $designate_internal_uri,
        region                      => $region,
        api_bind_port               => $api_bind_port,
        rabbit_user                 => $rabbit_user,
        rabbit_pass                 => $rabbit_pass,
        trove_guest_rabbit_user     => $trove_guest_rabbit_user,
        trove_guest_rabbit_pass     => $trove_guest_rabbit_pass,
        trove_service_user_pass     => $trove_service_user_pass,
        trove_quay_user             => $trove_quay_user,
        trove_quay_pass             => $trove_quay_pass,
        trove_dns_zone              => $trove_dns_zone,
        trove_dns_zone_id           => $trove_dns_zone_id,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    ferm::service { 'trove-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }

    openstack::db::project_grants { 'trove':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['trove-api'],
    }
}
