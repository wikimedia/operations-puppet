class role::wmcs::openstack::main::virt {
    include profile::openstack::main::cloudrepo
    include ::profile::openstack::labtestn::nova::common
    include ::profile::openstack::labtestn::nova::compute::service
}
