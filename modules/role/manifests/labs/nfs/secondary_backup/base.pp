class role::labs::nfs::secondary_backup::base {

    system::role { 'role::labs::nfs::secondary_backup':
        description => 'NFS shares secondary backup',
    }

    include labstore::backup_keys

    package { ['python3', 'python3-dateutil']:
        ensure  => present,
    }

    file {'/srv/backup':
        ensure  => 'directory',
    }

}
