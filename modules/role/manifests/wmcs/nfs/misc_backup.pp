class role::wmcs::nfs::misc_backup {
    system::role { $name: }

    include ::standard
    include ::profile::wmcs::nfs::backup_keys
    include ::profile::wmcs::nfs::misc_backup
}
