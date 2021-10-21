class role::backup::offsite {
    include ::profile::base::production
    include ::profile::backup::storage::main

    system::role { 'backup::offsite':
        description => 'Backup server (offsite storage)',
    }
}
