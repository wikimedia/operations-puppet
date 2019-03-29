class role::wmcs::openstack::codfw1dev::virt {
    system::role { $name: }
    include ::standard
    # include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::clientpackages
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::nova::common
    include ::profile::openstack::codfw1dev::nova::compute::service
    include ::profile::openstack::codfw1dev::envscripts
}
