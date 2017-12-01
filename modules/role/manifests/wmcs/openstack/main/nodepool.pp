class role::wmcs::openstack::main::nodepool {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::main::nodepool::service
}
