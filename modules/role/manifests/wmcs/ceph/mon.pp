class role::wmcs::ceph::mon {
    system::role { $name: description => 'Ceph Monitor / Manager server.' }
    include profile::base::production
    include profile::base::firewall
    include profile::base::cloud_production
    # potential chicken-egg problem with the next two profiles bc the admin keyring:
    include profile::cloudceph::auth::load_all
    include profile::cloudceph::mon
}
