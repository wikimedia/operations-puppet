class openstack::glance::service(
    $openstack_version=$::openstack::version,
    $glance_data = '/srv/glance/',
    $active_server,
    $standby_server,
    $keystone_host,
    $glanceconfig,
    $keystoneconfig,
) {
    include openstack::repo

    $glance_images_dir = "${glance_data}/images"
    $keystone_host_ip  = ipresolve($keystone_host,4)
    $keystone_auth_uri = "http://${active_server}:5000/v2.0"

    # Set up a keypair and rsync image files between active and standby
    user { 'glancesync':
        ensure     => present,
        name       => 'glancesync',
        shell      => '/bin/sh',
        comment    => 'glance rsync user',
        gid        => 'glance',
        managehome => true,
        require    => Package['glance'],
        system     => true,
    }

    ssh::userkey { 'glancesync':
        ensure  => present,
        require => User['glancesync'],
        content => secret('ssh/glancesync/glancesync.pub'),
    }

    package { 'glance':
        ensure  => present,
        require => Class['openstack::repo'],
    }


    #  This is 775 so that the glancesync user can rsync to it.
    file { $glance_data:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0775',
    }

    file { $glance_images_dir:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0775',
    }

    file {
        '/etc/glance/glance-api.conf':
            content => template("openstack/${$openstack_version}/glance/glance-api.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service['glance-api'],
            require => Package['glance'],
            mode    => '0440';
        '/etc/glance/glance-registry.conf':
            content => template("openstack/${$openstack_version}/glance/glance-registry.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service['glance-registry'],
            require => Package['glance'],
            mode    => '0440';
    }

    file { '/home/glancesync/.ssh':
        ensure  => directory,
        owner   => 'glancesync',
        group   => 'glance',
        mode    => '0700',
        require => User['glancesync'],
    }

    file { '/home/glancesync/.ssh/id_rsa':
        content => secret('ssh/glancesync/glancesync.key'),
        owner   => 'glancesync',
        group   => 'glance',
        mode    => '0600',
        require => File['/home/glancesync/.ssh'],
    }

    if $::fqdn == $active_server {
        service { 'glance-api':
            ensure  => running,
            require => Package['glance'],
        }

        service { 'glance-registry':
            ensure  => running,
            require => Package['glance'],
        }

        if $spandby_server != $active_server {
            cron { 'rsync_glance_images':
                command => "/usr/bin/rsync -aS ${glance_images_dir}/* ${standby_server}:${glance_images_dir}/",
                minute  => 15,
                user    => 'glancesync',
                require => User['glancesync'],
            }
        } else {
            # If the active and the standby are the same, it's not useful to sync
            cron { 'rsync_glance_images':
                ensure => absent,
            }
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
        cron { 'rsync_chown_images':
            command => "chown -R glance ${glance_images_dir}/*",
            minute  => 30,
            user    => 'root',
        }
    }
}
