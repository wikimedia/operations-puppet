class role::labs::nfs::secondary_backup::misc {

    include role::labs::nfs::secondary_backup::base

    file { '/srv/backup/misc':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    labstore::device_backup { 'secondary-misc':
        remotehost          => 'labstore1004.eqiad.wmnet',
        remote_vg           => 'misc',
        remote_lv           => 'misc-project',
        remote_snapshot     => 'misc-snap',
        local_vg            => 'backup',
        local_lv            => 'misc-project',
        local_snapshot      => 'misc-project-backup',
        local_snapshot_size => '2T',
        weekday             => 'wednesday',
        hour                => 20,
    }

}
