class role::backup::offsite {
    include ::profile::standard
    include ::profile::backup::storage

    system::role { 'backup::offsite':
        description => 'Backup server (offsite storage)',
    }
}
