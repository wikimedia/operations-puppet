class profile::wmcs::nfs::misc_backup {

    include profile::wmcs::nfs::backup_keys
    include profile::wmcs::nfs::bdsync
    include profile::wmcs::nfs::snapshot_manager

    file {'/srv/backup':
        ensure  => 'directory',
    }

    file { '/srv/backup/misc':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    profile::wmcs::nfs::device_backup { 'misc-scratch':
        remotehost          => 'cloudstore1008.wikimedia.org',
        remote_vg           => 'srv',
        remote_lv           => 'scratch',
        remote_snapshot     => 'scratch-snap',
        local_vg            => 'backup',
        local_lv            => 'scratch',
        local_snapshot      => 'scratch-backup',
        local_snapshot_size => '4T',
        interval            => '*-*-* *:00:00', # hourly
    }

    profile::wmcs::nfs::device_backup { 'misc-maps':
        remotehost          => 'cloudstore1008.wikimedia.org',
        remote_vg           => 'srv',
        remote_lv           => 'maps',
        remote_snapshot     => 'maps-snap',
        local_vg            => 'backup',
        local_lv            => 'maps',
        local_snapshot      => 'maps-backup',
        local_snapshot_size => '8T',
        interval            => '*-*-* *:30:00', # hourly
    }

}
