class role::wmcs::ceph::mon {
    system::role { $name: description => 'Ceph Monitor / Manager server.' }
    include profile::base::production
    include profile::base::firewall
    # potential chicken-egg problem with the next two profiles bc the admin keyring:
    include profile::ceph::auth::load_all
    include profile::ceph::mon
}
