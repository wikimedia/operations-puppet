class role::wmcs::openstack::labtestn::virt {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::nova::common
    include ::profile::openstack::labtestn::nova::compute::service
}
