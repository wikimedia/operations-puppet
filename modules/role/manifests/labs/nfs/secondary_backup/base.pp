class role::labs::nfs::secondary_backup::base {

    system::role { 'labs::nfs::secondary_backup':
        description => 'NFS shares secondary backup',
    }

    include labstore::backup_keys

    file {'/srv/backup':
        ensure  => 'directory',
    }

}
