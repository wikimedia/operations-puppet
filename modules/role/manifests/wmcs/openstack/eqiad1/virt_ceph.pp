# Temporary class used for testing Ceph based block storage on CloudVPS hypervisors
#
class role::wmcs::openstack::eqiad1::virt_ceph {
    system::role { $name: }
    include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::ceph::client::rbd
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::nova::common
    include ::profile::openstack::eqiad1::nova::compute::service
    include ::profile::openstack::eqiad1::envscripts
}
