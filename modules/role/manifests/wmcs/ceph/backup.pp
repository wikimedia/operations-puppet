class role::wmcs::ceph::backup {
    system::role { $name: description => 'Ceph Backy2 backup server' }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include profile::wmcs::backy2
    include profile::ceph::client::rbd
}
