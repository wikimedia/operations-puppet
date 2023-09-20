# Nova hypervisors with ceph for instance storage
# Most of the differences (if not all) will come from hiera parameters
# see role/eqiad/wmcs/openstack/eqiad1/virt_ceph.yaml
class role::wmcs::openstack::eqiad1::virt_ceph {
    system::role { $name: }
    include profile::base::production
    # include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet
    include profile::cloudceph::client::rbd_libvirt
    include profile::openstack::eqiad1::clientpackages
    include profile::openstack::eqiad1::envscripts
    include profile::openstack::eqiad1::nova::common
    include profile::openstack::eqiad1::nova::compute::service
    include profile::openstack::eqiad1::observerenv
    include profile::cloudceph::auth::deploy
}
