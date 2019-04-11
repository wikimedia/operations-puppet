class profile::wmcs::nfs::backup::primary::base {
    class {'labstore::backup_keys': }

    file {'/srv/backup':
        ensure  => 'directory',
    }
}
