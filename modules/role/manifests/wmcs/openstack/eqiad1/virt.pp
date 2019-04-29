class role::wmcs::openstack::eqiad1::virt {
    system::role { $name: }
    include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::nova::common
    include ::profile::openstack::eqiad1::nova::compute::service
    include ::profile::openstack::eqiad1::envscripts
}
