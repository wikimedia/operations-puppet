class role::wmcs::openstack::labtest::virt {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtest::serverpackages
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::compute::service
    include ::profile::openstack::labtest::envscripts
}
