# SPDX-License-Identifier: Apache-2.0

class openstack::glance::service::yoga(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_internal_uri,
    Stdlib::Port $api_bind_port,
    Array[String] $glance_backends,
    String $ceph_pool,
) {
    require "openstack::serverpackages::yoga::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    file {
        '/etc/glance/glance-api.conf':
            content   => template('openstack/yoga/glance/glance-api.conf.erb'),
            owner     => 'glance',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['glance-api'],
            require   => Package['glance'];
        '/etc/glance/policy.yaml':
            source  => 'puppet:///modules/openstack/yoga/glance/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/init.d/glance-api':
            content => template('openstack/yoga/glance/glance-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-api-uwsgi.ini':
            content => template('openstack/yoga/glance/glance-api-uwsgi.ini.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }

    group { 'glance':
        ensure => 'present',
        name   => 'glance',
        system => true,
    }

    user { 'glance':
        ensure     => 'present',
        name       => 'glance',
        comment    => 'glance system user',
        gid        => 'glance',
        managehome => true,
        require    => Package['glance'],
        system     => true,
    }
}
