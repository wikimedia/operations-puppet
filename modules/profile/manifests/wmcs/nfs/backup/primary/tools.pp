class profile::wmcs::nfs::backup::primary::tools (
    String $passive_server = lookup(
        'profile::wmcs::nfs::primary::passive_server',
        String,
        'first',
        'labstore1005.eqiad.wmnet'
    ),
){
    file { '/srv/backup/tools':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    labstore::device_backup { 'primary-tools':
        remotehost          => $passive_server,
        remote_vg           => 'tools',
        remote_lv           => 'tools-project',
        remote_snapshot     => 'tools-snap',
        local_vg            => 'backup',
        local_lv            => 'tools-project',
        local_snapshot      => 'tools-project-backup',
        local_snapshot_size => '2T',
        interval            => 'Tue *-*-* 20:00:00',
    }
}
