class role::wmcs::nfs::secondary {
    system::role { $name:
        description => 'NFS secondary share cluster',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::wmcs::nfs::ferm
    include ::profile::wmcs::nfs::rsync::ferm
    include ::profile::wmcs::nfs::rsync
    include ::profile::wmcs::nfs::secondary
}
