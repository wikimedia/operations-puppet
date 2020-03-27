class role::wmcs::openstack::codfw1dev::virt {
    system::role { $name: }
    include ::profile::standard
    # include ::profile::base::firewall
    # NOTE: ceph is not enabled in this role. Starting in Queens
    #       ceph-common is a dependency for the nova-common package
    include ::profile::ceph::common
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::nova::common
    include ::profile::openstack::codfw1dev::nova::compute::service
    include ::profile::openstack::codfw1dev::envscripts
}
