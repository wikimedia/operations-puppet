class role::wmcs::nfs::primary_backup::tools {
    system::role { $name:
        description => 'NFS shares primary backup (tools)',
    }
    include ::standard
    include profile::wmcs::nfs::backup::primary::base
    include profile::wmcs::nfs::backup::primary::tools
}
