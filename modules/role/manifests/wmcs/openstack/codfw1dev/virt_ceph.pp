# Nova hypervisors with ceph for instance storage
#
class role::wmcs::openstack::codfw1dev::virt_ceph {
    include profile::base::production
    # include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloud_private_subnet
    include profile::cloudceph::client::rbd_libvirt
    include profile::openstack::codfw1dev::clientpackages
    include profile::openstack::codfw1dev::observerenv
    include profile::openstack::codfw1dev::nova::common
    include profile::openstack::codfw1dev::nova::compute::service
    include profile::openstack::codfw1dev::envscripts
    include profile::cloudceph::auth::deploy
}
