class openstack::glance::service(
    $openstack_version=$::openstack::version,
    $glanceconfig) {
    include openstack::repo

    $image_datadir = '/a/glance/images'

    package { [ "glance" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "glance-api":
        ensure  => running,
        require => Package["glance"];
    }

    service { "glance-registry":
        ensure  => running,
        require => Package["glance"];
    }

    file {
        "/etc/glance/glance-api.conf":
            content => template("openstack/${$openstack_version}/glance/glance-api.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service["glance-api"],
            require => Package["glance"],
            mode    => '0440';
        "/etc/glance/glance-registry.conf":
            content => template("openstack/${$openstack_version}/glance/glance-registry.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service["glance-registry"],
            require => Package["glance"],
            mode    => '0440';
    }
    if ($openstack_version == "essex") {
        # Keystone config was (thankfully) moved out of the paste config
        # So, past essex we don't need to change these.
        file {
            "/etc/glance/glance-api-paste.ini":
                content => template("openstack/${$openstack_version}/glance/glance-api-paste.ini.erb"),
                owner   => 'glance',
                group   => 'glance',
                notify  => Service["glance-api"],
                require => Package["glance"],
                mode    => '0440';
            "/etc/glance/glance-registry-paste.ini":
                content => template("openstack/${$openstack_version}/glance/glance-registry-paste.ini.erb"),
                owner   => 'glance',
                group   => 'glance',
                notify  => Service["glance-registry"],
                require => Package["glance"],
                mode    => '0440';
        }
    }

    $spare_glance_host = hiera('labs_nova_controller_spare')
    # Set up a keypair and rsync image files between the main glance server
    #  and the spare.
    ssh::userkey { 'glance':
        require => Package['glance'],
        ensure  => present,
        source  => 'puppet:///private/ssh/glance/glance.pub',
    }
    file { '/var/lib/glance/.ssh':
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        mode    => '0700',
        require => Package['glance'],
    }
    file { '/var/lib/glance/.ssh/id_rsa':
        source  => 'puppet:///private/ssh/glance/glance.key',
        owner   => 'glance',
        group   => 'glance',
        mode    => '0600',
        require => File['/var/lib/glance/.ssh'],
    }
    cron { 'rsync_glance_images':
        command     => "/usr/bin/rsync -aS ${image_datadir} ${spare_glance_host}:${image_datadir}",
        minute      => 15,
        user        => 'glance',
    }
}
