# SPDX-License-Identifier: Apache-2.0

class profile::openstack::eqiad1::octavia(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Boolean $active = lookup('profile::openstack::eqiad1::octavia::active'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::eqiad1::octavia::db_host'),
    String $db_pass = lookup('profile::openstack::eqiad1::octavia::db_pass'),
    String $db_user = lookup('profile::openstack::eqiad1::octavia::db_host'),
    String $db_name = lookup('profile::openstack::eqiad1::octavia::db_name'),
    String $octavia_project_id = lookup('profile::openstack::eqiad1::octavia::octavia_project_id'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::octavia::api_bind_port'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::octavia::service_user_pass'),
    String $rabbit_pass = lookup('profile::openstack::eqiad1::octavia::rabbit_pass'),
    String $region = lookup('profile::openstack::eqiad1::region'),
    String $ca_passphrase = lookup('profile::openstack::eqiad1::octavia::ca_passphrase'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    String $amphora_secgroup = lookup('profile::openstack::eqiad1::octavia::amphora_secgroup'),
    String $amphora_boot_network = lookup('profile::openstack::eqiad1::octavia::amphora_boot_network'),
    String $amphora_flavor = lookup('profile::openstack::eqiad1::octavia::amphora_flavor'),
    Stdlib::IP::Address::V4::CIDR $amphora_mgmt_cidr = lookup('profile::openstack::eqiad1::octavia::amphora_mgmt_cidr'),
    Stdlib::IP::Address::V6::CIDR $amphora_mgmt_cidr_v6 = lookup('profile::openstack::eqiad1::octavia::amphora_mgmt_cidr_v6'),
    String $heartbeat_key = lookup('profile::openstack::eqiad1::octavia::heartbeat_key'),
) {
    class {'::profile::openstack::base::octavia':
        version                 => $version,
        active                  => $active,
        openstack_control_nodes => $openstack_control_nodes,
        rabbitmq_nodes          => $rabbitmq_nodes,
        keystone_fqdn           => $keystone_fqdn,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        db_name                 => $db_name,
        api_bind_port           => $api_bind_port,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_pass             => $rabbit_pass,
        ca_passphrase           => $ca_passphrase,
        region                  => $region,
        haproxy_nodes           => $haproxy_nodes,
        amphora_secgroup        => $amphora_secgroup,
        amphora_boot_network    => $amphora_boot_network,
        amphora_flavor          => $amphora_flavor,
        amphora_mgmt_cidr       => $amphora_mgmt_cidr,
        amphora_mgmt_cidr_v6    => $amphora_mgmt_cidr_v6,
        heartbeat_key           => $heartbeat_key,
        octavia_project_id      => $octavia_project_id,
    }

    file { '/etc/octavia/certs':
        ensure => directory,
        owner  => 'octavia',
        group  => 'octavia',
        mode   => '0700',
    }

    file { '/etc/octavia/certs/client.cert-and-key.pem':
        owner     => 'octavia',
        group     => 'octavia',
        mode      => '0600',
        show_diff => false,
        content   => secret('openstack/eqiad1/octavia/client.cert-and-key.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/server_ca.key.pem':
        owner     => 'octavia',
        group     => 'octavia',
        mode      => '0600',
        show_diff => false,
        content   => secret('openstack/eqiad1/octavia/server_ca.key.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/client_ca.cert.pem':
        owner     => 'octavia',
        group     => 'octavia',
        show_diff => false,
        content   => secret('openstack/eqiad1/octavia/client_ca.cert.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/server_ca.cert.pem':
        owner     => 'octavia',
        group     => 'octavia',
        show_diff => false,
        content   => secret('openstack/eqiad1/octavia/server_ca.cert.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/id_rsa':
        ensure    => 'present',
        mode      => '0600',
        owner     => 'osstackcanary',
        group     => 'osstackcanary',
        content   => secret('openstack/eqiad1/octavia/amphorakey'),
        show_diff => false,
    }
}
