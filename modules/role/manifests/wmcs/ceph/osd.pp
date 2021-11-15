class role::wmcs::ceph::osd {
    system::role { $name: description => 'Ceph Object Storage Daemon server.' }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::ceph::osd
    include profile::ceph::auth::deploy
}
