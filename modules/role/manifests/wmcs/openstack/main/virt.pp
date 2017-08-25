class role::wmcs::openstack::main::virt {
    include profile::openstack::main::cloudrepo
    include ::profile::openstack::main::nova::common
    include ::profile::openstack::main::nova::compute::service
}
