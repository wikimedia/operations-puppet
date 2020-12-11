class openstack::glance::service(
    $active,
    $version,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $glance_image_dir,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $registry_bind_port,
    String $ceph_pool,
    $glance_backends,
) {

    class { "openstack::glance::service::${version}":
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        glance_data_dir     => $glance_data_dir,
        ldap_user_pass      => $ldap_user_pass,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
        api_bind_port       => $api_bind_port,
        registry_bind_port  => $registry_bind_port,
        glance_backends     => $glance_backends,
        ceph_pool           => $ceph_pool,
    }

    file { $glance_data_dir:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0755',
    }

    # Glance expects some images that are actually in /srv/glance/images to
    #  be in /a/glance/images instead.  This link should keep everyone happy.
    file {'/a':
        ensure => link,
        target => '/srv',
    }

    service { 'glance-api':
        ensure  => $active,
        require => Package['glance'],
    }

    service { 'glance-registry':
        ensure  => $active,
        require => Package['glance'],
    }

    rsyslog::conf { 'glance':
        source   => 'puppet:///modules/openstack/glance/glance.rsyslog.conf',
        priority => 20,
    }
}
