class role::backup {
    # We actually want to be able to backup ourselves
    include ::profile::backup::host
    include ::profile::backup::director
    include ::profile::backup::storage
    include ::standard

    system::role { 'backup':
        description => 'Backup server',
    }
}
