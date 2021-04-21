class role::wmcs::nfs::secondary_drbd {
    system::role { $name:
        description => 'NFS secondary share cluster',
    }

    include profile::standard
    include profile::base::firewall
    include profile::wmcs::nfs::ferm
    include profile::wmcs::nfs::rsync::ferm
    ## enable after initial storage config T224747
    # include profile::wmcs::nfs::rsync
    include profile::ldap::client::labs
    include profile::wmcs::nfs::secondary_drbd
}
