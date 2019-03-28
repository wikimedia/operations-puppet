class openstack::glance::service(
    $active,
    $version,
    $nova_controller_standby,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data,
    $glance_image_dir,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
) {

    class { "openstack::glance::service::${version}":
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        glance_data         => $glance_data,
        ldap_user_pass      => $ldap_user_pass,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
    }

    file { $glance_data:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0755',
    }

    #  This is 775 so that the glancesync user can rsync to it.
    if ($active) and ($::fqdn != $nova_controller_standby) {
        file { $glance_image_dir:
            ensure  => directory,
            owner   => 'glance',
            group   => 'glance',
            require => Package['glance'],
            mode    => '0775',
        }
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
}
