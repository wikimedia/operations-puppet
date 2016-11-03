class role::labs::nfs::secondary_backup::base {

    system::role { 'role::labs::nfs::secondary_backup':
        description => 'NFS shares secondary backup',
    }

    include labstore::backup_keys

    file {'/srv/backup':
        ensure  => 'directory',
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
