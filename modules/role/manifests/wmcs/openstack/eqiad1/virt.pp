class role::wmcs::openstack::eqiad1::virt {
    system::role { $name: }
    include ::profile::standard
    # include ::profile::base::firewall
    # NOTE: ceph is not enabled in this role. Starting in Queens
    #       ceph-common is a dependency for the nova-common package
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::nova::common
    include ::profile::openstack::eqiad1::nova::compute::service
    include ::profile::openstack::eqiad1::envscripts
    include ::profile::ceph::client::rbd_libvirt
}
