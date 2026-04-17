# SPDX-License-Identifier: Apache-2.0

class openstack::octavia::service::flamingo(
    String $db_user,
    String $region,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Array[Stdlib::IP::Address] $control_nodes,
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
    String $amphora_flavor,
    String $amphora_boot_network,
    String $heartbeat_key,
    String $octavia_project_id,
) {
    $packages = [
        'octavia-api',
        'octavia-health-manager',
        'octavia-housekeeping',
        'octavia-worker',
        'python3-octavia',
        'python3-octaviaclient'
    ]
    package { $packages:
        ensure  => 'present',
    }

    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'octavia'
    $keystone_auth_project = 'octavia'
    file {
        '/etc/octavia/octavia.conf':
            content   => template('openstack/flamingo/octavia/octavia.conf.erb'),
            owner     => 'octavia',
            group     => 'octavia',
            mode      => '0440',
            show_diff => false,
            notify    => Service['octavia-api'],
            require   => Package['octavia-api'];
    }
    file {
        '/etc/octavia/policy.yaml':
            source  => 'puppet:///modules/openstack/flamingo/octavia/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['octavia-api'],
            require => Package['octavia-api'];
    }
}
