# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::octavia(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Boolean $active = lookup('profile::openstack::codfw1dev::octavia::active'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::octavia::db_host'),
    String $db_pass = lookup('profile::openstack::codfw1dev::octavia::db_pass'),
    String $db_user = lookup('profile::openstack::codfw1dev::octavia::db_host'),
    String $db_name = lookup('profile::openstack::codfw1dev::octavia::db_name'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::octavia::api_bind_port'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::octavia::service_user_pass'),
    String $rabbit_pass = lookup('profile::openstack::codfw1dev::octavia::rabbit_pass'),
    String $region = lookup('profile::openstack::codfw1dev::region'),
    String $ca_passphrase = lookup('profile::openstack::codfw1dev::octavia::ca_passphrase'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::codfw1dev::haproxy_nodes'),
    String $amphora_secgroup = lookup('profile::openstack::codfw1dev::octavia::amphora_secgroup'),
    String $amphora_boot_network = lookup('profile::openstack::codfw1dev::octavia::amphora_boot_network'),
    Stdlib::IP::Address::V4::CIDR $amphora_mgmt_cidr = lookup('profile::openstack::codfw1dev::octavia::amphora_mgmt_cidr'),
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
        amphora_mgmt_cidr       => $amphora_mgmt_cidr,
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
        content   => secret('openstack/octavia/client.cert-and-key.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/server_ca.key.pem':
        owner     => 'octavia',
        group     => 'octavia',
        mode      => '0600',
        show_diff => false,
        content   => secret('openstack/octavia/server_ca.key.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/client_ca.cert.pem':
        owner     => 'octavia',
        group     => 'octavia',
        show_diff => false,
        content   => secret('openstack/octavia/client_ca.cert.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/server_ca.cert.pem':
        owner     => 'octavia',
        group     => 'octavia',
        show_diff => false,
        content   => secret('openstack/octavia/server_ca.cert.pem'),
        require   => File['/etc/octavia/certs'],
    }
    file { '/etc/octavia/certs/id_rsa':
        ensure    => 'present',
        mode      => '0600',
        owner     => 'osstackcanary',
        group     => 'osstackcanary',
        content   => secret('openstack/octavia/amphorakey'),
        show_diff => false,
    }
}
