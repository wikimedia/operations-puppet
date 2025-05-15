# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::octavia(
    String $version = lookup('profile::openstack::base::version'),
    Boolean $active = lookup('profile::openstack::base::octavia::active'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $region = lookup('profile::openstack::base::region'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::octavia::db_host'),
    String $db_user = lookup('profile::openstack::base::octavia::db_user'),
    String $db_name = lookup('profile::openstack::base::octavia::db_name'),
    String $db_pass = lookup('profile::openstack::base::octavia::db_pass'),
    String $ldap_user_pass = lookup('profile::openstack::base::octavia::service_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::octavia::api_bind_port'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    String $rabbit_user = lookup('profile::openstack::base::octavia::rabbit_user'),
    String $rabbit_pass = lookup('profile::openstack::base::octavia::rabbit_pass'),
    String $ca_passphrase = lookup('profile::openstack::base::octavia::ca_passphrase'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    String $amphora_secgroup = lookup('profile::openstack::base::octavia::amphora_secgroup'),
    String $amphora_boot_network = lookup('profile::openstack::base::octavia::amphora_boot_network'),
    Stdlib::IP::Address::V4::CIDR $amphora_mgmt_cidr = lookup('profile::openstack::base::octavia::amphora_mgmt_cidr'),
    Stdlib::IP::Address::V6::CIDR $amphora_mgmt_cidr_v6 = lookup('profile::openstack::base::octavia::amphora_mgmt_cidr_v6'),
) {

    $control_nodes = $openstack_control_nodes.map |$node| { ipresolve($node['cloud_private_fqdn'], 4) }

    class { '::openstack::octavia::service':
        version              => $version,
        memcached_nodes      => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        rabbitmq_nodes       => $rabbitmq_nodes,
        keystone_fqdn        => $keystone_fqdn,
        db_user              => $db_user,
        db_pass              => $db_pass,
        db_name              => $db_name,
        db_host              => $db_host,
        api_bind_port        => $api_bind_port,
        ldap_user_pass       => $ldap_user_pass,
        rabbit_user          => $rabbit_user,
        rabbit_pass          => $rabbit_pass,
        ca_passphrase        => $ca_passphrase,
        region               => $region,
        amphora_secgroup     => $amphora_secgroup,
        amphora_boot_network => $amphora_boot_network,
        control_nodes        => $control_nodes,
    }

    ferm::service { 'octavia-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => $haproxy_nodes,
    }

    ferm::service { 'octavia-amphora-healthcheck':
        proto  => 'tcp',
        port   => 5555,
        srange => [$amphora_mgmt_cidr, $amphora_mgmt_cidr_v6],
    }

    ferm::service { 'octavia-amphora-healthcheck-udp':
        proto  => 'udp',
        port   => 5555,
        srange => [$amphora_mgmt_cidr, $amphora_mgmt_cidr_v6],
    }

    openstack::db::project_grants { 'octavia':
        access_hosts => $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['octavia-api'],
    }
}
