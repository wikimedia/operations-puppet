class openstack::glance::service(
    $active,
    $version,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_internal_uri,
    Stdlib::Port $api_bind_port,
    String $ceph_pool,
    $glance_backends,
) {

    class { "openstack::glance::service::${version}":
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        glance_data_dir       => $glance_data_dir,
        ldap_user_pass        => $ldap_user_pass,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_internal_uri => $keystone_internal_uri,
        api_bind_port         => $api_bind_port,
        glance_backends       => $glance_backends,
        ceph_pool             => $ceph_pool,
    }

    file { $glance_data_dir:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0755',
    }

    service { 'glance-api':
        ensure  => $active,
        require => Package['glance'],
    }

    rsyslog::conf { 'glance':
        source   => 'puppet:///modules/openstack/glance/glance.rsyslog.conf',
        priority => 20,
    }
}
