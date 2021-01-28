class role::backup::archive_backup {
    include ::profile::standard
    include ::profile::backup::storage
    include ::profile::backup::host
    include ::profile::backup::archive_backup

    system::role { 'backup::archive_backup':
        description => 'Backup server (offsite storage) + archive backup',
    }
}
