class role::wmcs::openstack::labtest::virt {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::compute::service
    include ::profile::openstack::labtest::envscripts
}
