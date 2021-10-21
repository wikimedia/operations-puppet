class role::wmcs::nfs::secondary {
    system::role { $name:
        description => 'NFS secondary share cluster',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::ldap::client::labs
    include ::profile::wmcs::nfs::secondary
}
