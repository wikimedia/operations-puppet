# SPDX-License-Identifier: Apache-2.0

class openstack::placement::service::yoga(
    $openstack_controllers,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
    Stdlib::Port $api_bind_port,
) {
    require "openstack::serverpackages::yoga::${::lsbdistcodename}"

    package { 'placement-api':
        ensure => 'present',
    }

    file {
        '/etc/placement/placement.conf':
            content   => template('openstack/yoga/placement/placement.conf.erb'),
            owner     => 'placement',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['placement-api'],
            require   => Package['placement-api'];
        '/etc/placement/policy.yaml':
            source  => 'puppet:///modules/openstack/yoga/placement/policy.yaml',
            owner   => 'placement',
            group   => 'placement',
            mode    => '0644',
            require => Package['placement-api'];
        '/etc/init.d/placement-api':
            content => template('openstack/yoga/placement/placement-api.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['placement-api'],
            require => Package['placement-api'];
    }
}
