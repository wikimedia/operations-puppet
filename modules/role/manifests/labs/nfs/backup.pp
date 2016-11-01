class role::labs::nfs::backup {
    system::role { 'role::labs::nfs::backup':
        description => 'NFS shares backup dest',
    }
    include labstore::backup_keys

    file { '/srv/eqiad/maps':
        ensure => 'directory',
    }

    file { '/srv/eqiad/tools':
        ensure => 'directory',
    }

    file { '/srv/eqiad/others':
        ensure => 'directory',
    }

    mount { '/srv/eqiad/maps':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/backup/maps',
        require => File['/srv/eqiad/maps'],
    }

    mount { '/srv/eqiad/tools':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/backup/tools',
        require => File['/srv/scratch'],
    }

    mount { '/srv/eqiad/others':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/backup/others',
        require => File['/srv/statistics'],
    }

    labstore::device_backup { 'secondary-test':
        remotehost      => 'labstore1005.eqiad.wmnet',
        remote_vg       => 'misc',
        remote_lv       => 'test',
        remote_snapshot => 'testsnap',
        localdev        => '/dev/backup/test',
        weekday         => 'monday',
    }
}
