class role::wmcs::openstack::main::virt {
    system::role { $name: }
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::compute::service
    include ::profile::openstack::main::envscripts
}
