class role::wmcs::ceph::mon {
    system::role { $name: description => 'Ceph Monitor / Manager server.' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::lvs::realserver
    include ::profile::ceph::mon
}
