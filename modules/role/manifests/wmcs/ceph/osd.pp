class role::wmcs::ceph::osd {
    system::role { $name: }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::ceph::osd
}
