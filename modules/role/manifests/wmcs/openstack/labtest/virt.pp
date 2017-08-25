class role::wmcs::openstack::labtest::virt {
    include profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::nova::common
    include ::profile::openstack::labtest::nova::compute::service
}
