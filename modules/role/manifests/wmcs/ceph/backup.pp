class role::wmcs::ceph::backup {
    system::role { $name: description => 'Ceph Backy2 backup server' }
    include ::profile::standard
    include ::profile::base::firewall

    include profile::wmcs::backy2
    include profile::ceph::client::rbd
}
