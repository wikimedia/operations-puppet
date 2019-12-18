class role::wmcs::ceph::mon {
    system::role { $name: }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::lvs::realserver
    include ::profile::ceph::mon
}
