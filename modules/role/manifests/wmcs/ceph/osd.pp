class role::wmcs::ceph::osd {
    system::role { $name: description => 'Ceph Object Storage Daemon server.' }
    include ::profile::standard
    include ::profile::base::firewall
    # This does not really install it by default, controlled through hiera
    include ::profile::base::linux510
    include ::profile::ceph::osd
}
