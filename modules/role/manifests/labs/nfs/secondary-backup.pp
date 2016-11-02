class role::labs::nfs::secondary-backup {

    labstore::device_backup { 'secondary-test':
        remotehost      => 'labstore1005.eqiad.wmnet',
        remote_vg       => 'misc',
        remote_lv       => 'test',
        remote_snapshot => 'testsnap',
        localdev        => '/dev/backup/test',
        weekday         => 'monday',
    }
}
