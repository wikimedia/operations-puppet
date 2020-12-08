class openstack::cinder::service(
    $active,
    $version,
    $openstack_controllers,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $keystone_admin_uri,
    $keystone_public_uri,
    String $ceph_pool,
    Stdlib::Port $api_bind_port,
) {
    class { "openstack::cinder::service::${version}":
        openstack_controllers => $openstack_controllers,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_public_uri   => $keystone_public_uri,
        api_bind_port         => $api_bind_port,
        ceph_pool             => $ceph_pool,
    }

    service { 'cinder-scheduler':
        ensure  => $active,
        require => Package['cinder-scheduler'],
    }

    rsyslog::conf { 'cinder':
        source   => 'puppet:///modules/openstack/glance/glance.rsyslog.conf',
        priority => 40,
    }

    # The cinder packages create this user, but with a weird, non-system ID.
    #  Instead, create the user ahead of time with a proper uid.
    user { 'cinder':
        ensure     => 'present',
        name       => 'cinder',
        comment    => 'cinder system user',
        gid        => 'cinder',
        managehome => true,
        before     => Package['cinder-scheduler', 'cinder-api'],
        system     => true,
    }
}
