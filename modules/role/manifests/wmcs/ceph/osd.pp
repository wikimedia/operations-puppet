class role::wmcs::ceph::osd {
    system::role { $name: description => 'Ceph Object Storage Daemon server.' }
    include ::profile::base::production
    include ::profile::firewall
    include ::profile::base::cloud_production
    include profile::cloudceph::auth::deploy
    include profile::cloudceph::osd
}
