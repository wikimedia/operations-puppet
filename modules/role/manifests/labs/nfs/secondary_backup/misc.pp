class role::labs::nfs::secondary_backup::misc {

    include role::labs::nfs::secondary_backup::base

    file { '/srv/backup/misc':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    mount { '/srv/backup/misc':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/backup/misc-project',
        require => File['/srv/backup/misc'],
    }

    labstore::device_backup { 'secondary-misc':
        remotehost      => 'labstore1005.eqiad.wmnet',
        remote_vg       => 'misc',
        remote_lv       => 'misc-project',
        remote_snapshot => 'misc-snap',
        localdev        => '/dev/backup/misc-project',
        weekday         => 'tuesday',
    }

}
