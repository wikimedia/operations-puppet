class openstack2::glance::service(
    $active,
    $version,
    $nova_controller_ip,
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

    package { 'glance':
        ensure  => present,
    }

    file { $glance_data:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0755',
    }

    #  This is 775 so that the glancesync user can rsync to it.
    file { $glance_image_dir:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0775',
    }

    file {
        '/etc/glance/glance-api.conf':
            content => template("openstack2/${version}/glance/glance-api.conf.erb"),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template("openstack2/${version}/glance/glance-registry.conf.erb"),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            source  => "puppet:///modules/openstack2/${version}/glance/policy.json",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }

    if $active {

        service { 'glance-api':
            ensure  => running,
            require => Package['glance'],
        }

        service { 'glance-registry':
            ensure  => running,
            require => Package['glance'],
        }
    } else {
        service { 'glance-api':
            ensure  => stopped,
            require => Package['glance'],
        }

        service { 'glance-registry':
            ensure  => stopped,
            require => Package['glance'],
        }
    }
}
