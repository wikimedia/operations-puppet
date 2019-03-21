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

    if os_version('debian jessie') and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package { 'glance':
        ensure          => 'present',
        install_options => $install_options,
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

    file {
        '/etc/glance/glance-api.conf':
            content => template("openstack/${version}/glance/glance-api.conf.erb"),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template("openstack/${version}/glance/glance-registry.conf.erb"),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            source  => "puppet:///modules/openstack/${version}/glance/policy.json",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
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
