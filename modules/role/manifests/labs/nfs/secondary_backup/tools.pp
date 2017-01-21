class role::labs::nfs::secondary_backup::tools {

    include role::labs::nfs::secondary_backup::base

    file { '/srv/backup/tools':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    labstore::device_backup { 'secondary-tools':
        remotehost      => 'labstore1004.eqiad.wmnet',
        remote_vg       => 'tools',
        remote_lv       => 'tools-project',
        remote_snapshot => 'tools-snap',
        localdev        => '/dev/backup/tools-project',
        weekday         => 'tuesday',
        hour            => 20,
    }

}
