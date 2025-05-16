# SPDX-License-Identifier: Apache-2.0
class openstack::octavia::service(
    String $version,
    String $region,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Array[Stdlib::IP::Address] $control_nodes,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    Stdlib::Fqdn $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
    String $ca_passphrase,
    String $amphora_secgroup,
    String $amphora_boot_network,
    String $heartbeat_key,
) {
    class { "openstack::octavia::service::${version}":
        db_user              => $db_user,
        db_pass              => $db_pass,
        db_name              => $db_name,
        db_host              => $db_host,
        ldap_user_pass       => $ldap_user_pass,
        keystone_fqdn        => $keystone_fqdn,
        control_nodes        => $control_nodes,
        api_bind_port        => $api_bind_port,
        rabbit_user          => $rabbit_user,
        rabbit_pass          => $rabbit_pass,
        memcached_nodes      => $memcached_nodes,
        rabbitmq_nodes       => $rabbitmq_nodes,
        ca_passphrase        => $ca_passphrase,
        region               => $region,
        amphora_secgroup     => $amphora_secgroup,
        amphora_boot_network => $amphora_boot_network,
        heartbeat_key        => $heartbeat_key,
    }

    service { 'octavia-api':
        ensure    => running,
        require   => Package['octavia-api', 'python3-octavia'],
        subscribe => File['/etc/octavia/octavia.conf'],
    }
    service { 'octavia-health-manager':
        ensure    => running,
        require   => Package['octavia-health-manager', 'python3-octavia'],
        subscribe => File['/etc/octavia/octavia.conf'],
    }
    service { 'octavia-housekeeping':
        ensure    => running,
        require   => Package['octavia-housekeeping', 'python3-octavia'],
        subscribe => File['/etc/octavia/octavia.conf'],
    }
    service { 'octavia-worker':
        ensure    => running,
        require   => Package['octavia-worker', 'python3-octavia'],
        subscribe => File['/etc/octavia/octavia.conf'],
    }
}
