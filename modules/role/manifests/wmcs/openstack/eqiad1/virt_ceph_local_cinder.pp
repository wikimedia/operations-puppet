# SPDX-License-Identifier: Apache-2.0
#
# Nova hypervisors with ceph for instance storage and a cinder/lvm client
#
class role::wmcs::openstack::eqiad1::virt_ceph_local_cinder {
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
    include profile::openstack::eqiad1::cinder::volume
}
