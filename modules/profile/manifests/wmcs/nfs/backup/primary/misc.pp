class profile::wmcs::nfs::backup::primary::misc (
    String $passive_server = lookup(
        'profile::wmcs::nfs::primary::passive_server',
        String,
        'first',
        'labstore1005.eqiad.wmnet'
    ),
){

    include ::standard

    file { '/srv/backup/misc':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    labstore::device_backup { 'primary-misc':
        remotehost          => $passive_server,
        remote_vg           => 'misc',
        remote_lv           => 'misc-project',
        remote_snapshot     => 'misc-snap',
        local_vg            => 'backup',
        local_lv            => 'misc-project',
        local_snapshot      => 'misc-project-backup',
        local_snapshot_size => '2T',
        interval            => 'Wed *-*-* 20:00:00',
    }

}
