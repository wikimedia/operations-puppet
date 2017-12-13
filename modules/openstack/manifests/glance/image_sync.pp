class openstack::glance::image_sync(
    $active,
    $version,
    $glance_image_dir,
    $nova_controller_standby='',
) {

    require openstack::glance::service

    # Cron doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Set up a keypair and rsync image files between active and standby
    user { 'glancesync':
        ensure     => 'present',
        name       => 'glancesync',
        shell      => '/bin/sh',
        comment    => 'glance rsync user',
        gid        => 'glance',
        managehome => true,
        require    => Package['glance'],
        system     => true,
    }

    ssh::userkey { 'glancesync':
        ensure  => 'present',
        require => User['glancesync'],
        content => secret('ssh/glancesync/glancesync.pub'),
    }

    file { '/home/glancesync/.ssh':
        ensure  => directory,
        owner   => 'glancesync',
        group   => 'glance',
        mode    => '0700',
        require => User['glancesync'],
    }

    file { '/home/glancesync/.ssh/id_rsa':
        content   => secret('ssh/glancesync/glancesync.key'),
        owner     => 'glancesync',
        group     => 'glance',
        mode      => '0600',
        require   => File['/home/glancesync/.ssh'],
        show_diff => false,
    }

    if $active and !empty($nova_controller_standby) {
        cron { 'rsync_glance_images':
            ensure  => $ensure,
            command => "/usr/bin/rsync --delete --delete-after -aSO ${glance_image_dir}/ ${nova_controller_standby}:${glance_image_dir}/",
            minute  => 15,
            user    => 'glancesync',
            require => User['glancesync'],
        }
    }

    # If we are not the active server and are definitely
    # the standby then setup the permissions insurance
    # XXX: what is this for?
    if !($active) {

        if ($::fqdn == $nova_controller_standby) {
            $chown_ensure = 'present'
        }
        else {
            $chown_ensure = 'absent'
        }

        cron { 'rsync_chown_images':
            ensure  => $chown_ensure,
            command => "chown -R glance ${glance_image_dir}/*",
            minute  => 30,
            user    => 'root',
        }
    }
}
