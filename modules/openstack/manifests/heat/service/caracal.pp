# SPDX-License-Identifier: Apache-2.0

class openstack::heat::service::caracal(
    String $db_user,
    Array[Stdlib::Fqdn] $memcached_nodes,
    String $region,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    Stdlib::Fqdn $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $cfn_api_bind_port,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String $rabbit_user,
    String $rabbit_pass,
    String[32] $auth_encryption_key,
    String $domain_admin_pass,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
) {
    require "openstack::serverpackages::caracal::${::lsbdistcodename}"

    package { 'heat-api':
        ensure => 'present',
    }
    package { 'heat-api-cfn':
        ensure => 'present',
    }
    package { 'heat-engine':
        ensure => 'present',
    }

    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'heat'
    $keystone_auth_project = 'service'
    file {
        '/etc/heat/heat.conf':
            content   => template('openstack/caracal/heat/heat.conf.erb'),
            owner     => 'heat',
            group     => 'heat',
            mode      => '0440',
            show_diff => false,
            notify    => Service['heat-api', 'heat-engine', 'heat-api-cfn'],
            require   => Package['heat-api', 'heat-engine', 'heat-api-cfn'];
        '/etc/heat/policy.yaml':
            source  => 'puppet:///modules/openstack/caracal/heat/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['heat-api', 'heat-engine', 'heat-api-cfn'],
            require => Package['heat-api', 'heat-engine', 'heat-api-cfn'];
        '/etc/init.d/heat-api':
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('openstack/caracal/heat/heat-api.erb');
        '/etc/init.d/heat-api-cfn':
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('openstack/caracal/heat/heat-api-cfn.erb');
    }
}
