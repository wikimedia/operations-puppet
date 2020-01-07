class role::wmcs::ceph::osd {
    system::role { $name: description => 'Ceph Object Storage Daemon server.' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::ceph::osd
}
