# == openstack::glance::image_sync ==
#
# Transfers Glance images from primary file store to other server(s)
#
# === Parameters ===
# [*active*]
#    If these definitions should be present or absent
# [*glance_image_dir]
#    Directory where Glance stores its uploaded images
# [*openstack_controllers*]
#    List of all control nodes
#
class openstack::glance::image_sync(
    Boolean $active,
    String $glance_image_dir,
    Array[Stdlib::Fqdn] $openstack_controllers,
) {
    require openstack::glance::service

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

    # systemd::timer::job does not take a boolean
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # If we are the primary Glance image store, then sync images to the standby
    #
    # Note that our rsync never deletes anything; this is to prevent disaster if
    #  a secondary server gets confused and thinks it's the primary.
    $other_glance_hosts = $openstack_controllers - $::fqdn
    $other_glance_hosts.each |String $glance_host| {
        systemd::timer::job { "glance_rsync_images_${glance_host}":
            ensure                    => $ensure,
            description               => 'Copy Glance images to standby server',
            command                   => "/usr/bin/rsync -aSO ${glance_image_dir}/ ${glance_host}:${glance_image_dir}/",
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

    if ( !$active ) {
        # Make sure there's a directory for those files to land in
        file { $glance_image_dir:
            ensure => directory,
            owner  => 'glance',
            group  => 'glance',
            mode   => '0775',
        }
    }
}
