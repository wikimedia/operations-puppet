class role::wmcs::openstack::labtest::virt {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::compute::service
}
