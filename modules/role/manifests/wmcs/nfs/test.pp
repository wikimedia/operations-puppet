class role::wmcs::nfs::test {
    system::role { $name:
        description => 'NFS test cluster',
    }

    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::wmcs::nfs::test
}
