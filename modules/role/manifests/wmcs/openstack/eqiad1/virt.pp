# Nova hypervisors with local storage for instance storage (not ceph)
# Most of the differences (if not all) will come from hiera parameters
# see role/eqiad/wmcs/openstack/eqiad1/virt.yaml
class role::wmcs::openstack::eqiad1::virt {
    system::role { $name: }
    include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::ceph::client::rbd_libvirt
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::envscripts
    include ::profile::openstack::eqiad1::nova::common
    include ::profile::openstack::eqiad1::nova::compute::service
    include ::profile::openstack::eqiad1::observerenv
}
