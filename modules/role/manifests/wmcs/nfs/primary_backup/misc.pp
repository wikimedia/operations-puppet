class role::wmcs::nfs::primary_backup::misc {
    system::role { $name:
        description => 'NFS shares primary backup (misc)',
    }
    include profile::base::production
    include profile::wmcs::nfs::backup::primary::base
    include profile::wmcs::nfs::backup::primary::misc
}
