class role::labs::nfs::backup {
    system::role { 'role::labs::nfs::backup':
        description => 'NFS shares backup dest',
    }
    include labstore::backup_keys

    labstore::device_backup { 'secondary-test':
        remotehost      => 'labstore1005.eqiad.wmnet',
        remote_vg       => 'misc',
        remote_lv       => 'test',
        remote_snapshot => 'testsnap',
        localdev        => '/dev/backup/test',
        weekday         => 'monday',
    }
}
