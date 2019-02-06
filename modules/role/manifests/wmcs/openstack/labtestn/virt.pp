class role::wmcs::openstack::labtestn::virt {
    system::role { $name: }
    include ::standard
    # include ::profile::base::firewall
    include ::profile::openstack::labtestn::clientpackages
    include ::profile::openstack::labtestn::observerenv
    include ::profile::openstack::labtestn::nova::common
    include ::profile::openstack::labtestn::nova::compute::service
    include ::profile::openstack::labtestn::envscripts
}
