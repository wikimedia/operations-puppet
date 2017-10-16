class role::wmcs::openstack::main::nodepool {
    system::role { $name: }
    include ::profile::openstack::main::nodepool::service
}
