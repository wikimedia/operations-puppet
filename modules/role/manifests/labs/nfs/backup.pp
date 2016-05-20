class role::labs::nfs::backup {
    system::role { 'role::labs::nfs::backup':
        description => 'NFS shares backup dest',
    }
    include labstore::backup_keys
}
