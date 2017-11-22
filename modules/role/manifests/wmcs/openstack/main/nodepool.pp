class role::wmcs::openstack::main::nodepool {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::nodepool::service
}
