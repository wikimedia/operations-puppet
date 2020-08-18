class role::wmcs::nfs::secondary {
    system::role { $name:
        description => 'NFS secondary share cluster & ceph VM backup store',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::wmcs::nfs::rsync::ferm
    include ::profile::wmcs::nfs::rsync
    include ::profile::ldap::client::labs
    include ::profile::wmcs::nfs::secondary


    # For ceph backups:
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include profile::wmcs::backy2
    include profile::ceph::client::rbd
}
