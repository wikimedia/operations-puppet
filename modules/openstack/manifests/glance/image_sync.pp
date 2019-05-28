# == openstack::glance::image_sync ==
#
# Transfers Glance images from master to standby server
#
# === Parameters ===
# [*active*]
#    If these definitions should be present or absent
# [*glance_image_dir]
#    Directory where Glance stores its uploaded images
# [*nova_controller_standby*]
#    Hostname of the standby server
#
class openstack::glance::image_sync(
    Boolean $active,
    String $glance_image_dir,
    String $nova_controller_standby = undef,
) {
    require openstack::glance::service

    # systemd::timer::job does not take a boolean
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

    # If we are the master Glance server, then sync images to the standby
    if $active and $nova_controller_standby {

        # TODO: Remove after change is applied
        cron { 'rsync_glance_images':
            ensure => absent,
            user   => 'glancesync',
        }

        systemd::timer::job { 'glance_rsync_images':
            ensure                    => $ensure,
            description               => 'Copy Glance images to standby server',
            command                   => "/usr/bin/rsync -aSO ${glance_image_dir}/ ${nova_controller_standby}:${glance_image_dir}/",
            interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:15:00', # Every hour at minute 15
            },
            logging_enabled           => false,
            monitoring_enabled        => true,
            monitoring_contact_groups => 'wmcs-team',
            user                      => 'glancesync',
            require                   => User['glancesync'],
        }
    }

    # If we are the standby server, fix file ownership (glancesync->glance)
    if !($active) and ($::fqdn == $nova_controller_standby) {
        file { $glance_image_dir:
            ensure  => directory,
            owner   => 'glance',
            group   => 'glance',
            recurse => true,
        }
    }
}
