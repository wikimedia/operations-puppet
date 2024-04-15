# SPDX-License-Identifier: Apache-2.0

class openstack::placement::service::bobcat(
    Array[Stdlib::Fqdn] $memcached_nodes,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $ldap_user_pass,
    $keystone_fqdn,
    Stdlib::Port $api_bind_port,
) {
    require "openstack::serverpackages::bobcat::${::lsbdistcodename}"

    package { 'placement-api':
        ensure => 'present',
    }

    # Subtemplates of placement.conf are going to want to know what
    #  version this is
    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    file {
        '/etc/placement/placement.conf':
            content   => template('openstack/bobcat/placement/placement.conf.erb'),
            owner     => 'placement',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['placement-api'],
            require   => Package['placement-api'];
        '/etc/placement/policy.yaml':
            source  => 'puppet:///modules/openstack/bobcat/placement/policy.yaml',
            owner   => 'placement',
            group   => 'placement',
            mode    => '0644',
            require => Package['placement-api'];
        '/etc/init.d/placement-api':
            content => template('openstack/bobcat/placement/placement-api.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['placement-api'],
            require => Package['placement-api'];
    }
}
