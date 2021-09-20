class role::wmcs::nfs::standalone {
    system::role { $name:
        description => 'NFS server',
    }

    include ::profile::wmcs::nfs::standalone
}
