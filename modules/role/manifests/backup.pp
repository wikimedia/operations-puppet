class role::backup {
    # We actually want to be able to backup ourselves
    include ::profile::backup::host
    include ::profile::backup::director
    include ::standard

    system::role { 'role::backup':
        description => 'Backup server',
    }
}
