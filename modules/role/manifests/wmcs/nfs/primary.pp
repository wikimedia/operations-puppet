class role::wmcs::nfs::primary {
    system::role { $name:
        description => 'NFS primary share cluster',
    }

    include ::profile::base::production
    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::wmcs::nfs::primary
    include ::profile::wmcs::nfs::maintain_dbusers
}
