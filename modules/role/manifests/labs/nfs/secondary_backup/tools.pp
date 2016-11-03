class role::labs::nfs::secondary_backup::tools {

    include role::labs::nfs::secondary_backup::base

    file { '/srv/backup/tools':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    mount { '/srv/backup/tools':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/backup/tools-project',
        require => File['/srv/backup/tools'],
    }

    labstore::device_backup { 'secondary-tools':
        remotehost      => 'labstore1005.eqiad.wmnet',
        remote_vg       => 'tools',
        remote_lv       => 'tools-project',
        remote_snapshot => 'tools-snap',
        localdev        => '/dev/backup/tools-project',
        weekday         => 'monday',
    }

}
