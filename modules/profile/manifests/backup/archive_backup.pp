class profile::backup::archive_backup {
    backup::set { 'archive-backup':
        jobdefaults => 'Monthly-1st-Wed-Archive',
    }
}
