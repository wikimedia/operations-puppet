class role::wmcs::openstack::labtest::nodepool {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::nodepool::service
}
