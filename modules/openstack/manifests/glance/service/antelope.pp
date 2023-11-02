# SPDX-License-Identifier: Apache-2.0

class openstack::glance::service::antelope(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $ldap_user_pass,
    $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    Array[String] $glance_backends,
    String $ceph_pool,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
) {
    require "openstack::serverpackages::antelope::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    $version = inline_template("<%= @title.split(':')[-1] -%>")
    file {
        '/etc/glance/glance-api.conf':
            content   => template('openstack/antelope/glance/glance-api.conf.erb'),
            owner     => 'glance',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['glance-api'],
            require   => Package['glance'];
        '/etc/glance/policy.yaml':
            source  => 'puppet:///modules/openstack/antelope/glance/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/init.d/glance-api':
            content => template('openstack/antelope/glance/glance-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-api-uwsgi.ini':
            content => template('openstack/antelope/glance/glance-api-uwsgi.ini.erb'),
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

    # Apply https://review.opendev.org/c/openstack/glance_store/+/885581
    openstack::patch { '/usr/lib/python3/dist-packages/glance_store/_drivers/rbd.py':
        source  => 'puppet:///modules/openstack/antelope/glance/hacks/rbd.py.patch',
        require => Package['glance'],
        notify  => Service['glance-api'],
    }
}
