class openstack::cinder::service(
    $active,
    $version,
    $openstack_controllers,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $ldap_user_pass,
    $keystone_admin_uri,
    $region,
    String $ceph_pool,
    String $rabbit_user,
    String $rabbit_pass,
    String $libvirt_rbd_cinder_uuid,
    Stdlib::Port $api_bind_port,
) {
    class { "openstack::cinder::service::${version}":
        openstack_controllers   => $openstack_controllers,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        keystone_admin_uri      => $keystone_admin_uri,
        region                  => $region,
        api_bind_port           => $api_bind_port,
        ceph_pool               => $ceph_pool,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        libvirt_rbd_cinder_uuid => $libvirt_rbd_cinder_uuid,
    }

    service { 'cinder-scheduler':
        ensure  => $active,
        require => Package['cinder-scheduler'],
    }

    service { 'cinder-api':
        ensure  => $active,
        require => Package['cinder-api'],
    }

    service { 'cinder-volume':
        ensure  => $active,
        require => Package['cinder-volume'],
    }

    rsyslog::conf { 'cinder':
        source   => 'puppet:///modules/openstack/cinder/cinder.rsyslog.conf',
        priority => 40,
    }

    # The cinder packages create this user, but with a weird, non-system ID.
    #  Instead, create the user ahead of time with a proper uid.
    group { 'cinder':
        ensure => 'present',
        name   => 'cinder',
        system => true,
    }

    user { 'cinder':
        ensure     => 'present',
        name       => 'cinder',
        comment    => 'cinder system user',
        gid        => 'cinder',
        managehome => true,
        before     => Package['cinder-scheduler', 'cinder-api', 'cinder-volume'],
        system     => true,
    }
}
