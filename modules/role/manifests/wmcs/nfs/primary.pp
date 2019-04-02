class role::wmcs::nfs::primary {
    system::role { $name:
        description => 'NFS primary share cluster',
    }

    include ::standard
    include ::profile::wmcs::nfs::primary
    include ::profile::wmcs::nfs::maintain_dbusers
}
