class role::wmcs::ceph::mon {
    system::role { $name: description => 'Ceph Monitor / Manager server.' }
    include profile::base::production
    include profile::base::firewall
    include profile::ceph::mon
    include profile::ceph::auth::load_all
}
