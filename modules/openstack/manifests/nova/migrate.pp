class openstack::nova::migrate(
    $is_controller=false
){
    # Set up users and scripts to permit cold-migration between compute nodes.
    # This requires a keypair for scp
    user { 'novamigrate':
        ensure     => present,
        name       => 'novamigrate',
        shell      => '/bin/sh',
        comment    => 'nova user for cold-migration',
        gid        => 'nova',
        managehome => true,
        require    => Package['nova-compute'],
        system     => true,
    }
    ssh::userkey { 'novamigrate':
        content  => secret('novamigrate/novamigrate.pub'),
        require  => user['novamigrate'],
        ensure   => present,
    }
    file { '/home/novamigrate/.ssh':
        ensure  => directory,
        owner   => 'novamigrate',
        group   => 'nova',
        mode    => '0700',
        require => user['novamigrate'],
    }

    file { '/home/novamigrate/.ssh/id_rsa':
        content => secret('novamigrate/novamigrate'),
        owner   => 'novamigrate',
        group   => 'nova',
        mode    => '0600',
        require => File['/home/novamigrate/.ssh'],
    }

    if ($is_controller) {
        # Script to cold-migrate instances between compute nodes
        file { '/home/novamigrate/cold-migrate':
            ensure => present,
            source => "puppet:///modules/openstack/${openstack_version}/virtscripts/cold-migrate",
            mode   => '0755',
            owner  => 'novamigrate',
            group  => 'nova',
        }

        # Script to migrate instance from one dc to another
        # (specifically, pmtpa to eqiad)
        file { '/home/novamigrate/dc-migrate':
            ensure => present,
            source => "puppet:///modules/openstack/${openstack_version}/virtscripts/dc-migrate",
            mode   => '0755',
            owner  => 'novamigrate',
            group  => 'nova',
        }

        # Handy script to set up environment for commandline nova magic
        file { '/home/novamigrate/novaenv.sh':
            content => template('openstack/novaenv.sh.erb'),
            mode    => '0755',
            owner   => 'novamigrate',
            group   => 'nova',
        }
    }
}
