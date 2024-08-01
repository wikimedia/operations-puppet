# SPDX-License-Identifier: Apache-2.0

class profile::openstack::eqiad1::cinder::volume(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    String $region                      = lookup('profile::openstack::eqiad1::region'),
    String $db_pass                     = lookup('profile::openstack::eqiad1::cinder::db_pass'),
    Stdlib::Fqdn $db_host               = lookup('profile::openstack::eqiad1::cinder::db_host'),
    String $ceph_pool                   = lookup('profile::openstack::eqiad1::cinder::ceph_pool'),
    String $rabbit_pass                 = lookup('profile::openstack::eqiad1::cinder::rabbit_pass'),
    String $libvirt_rbd_cinder_uuid     = lookup('profile::cloudceph::client::rbd::libvirt_rbd_cinder_uuid'),
    String $ceph_rbd_client_name        = lookup('profile::openstack::eqiad1::cinder::ceph_rbd_client_name'),
    Array[String] $all_backend_names    = lookup('profile::openstack::eqiad1::cinder::all_backend_names'),
    String[1] $backend_type             = lookup('profile::openstack::eqiad1::cinder::backend_type'),
    String[1] $backend_name             = lookup('profile::openstack::eqiad1::cinder::backend_name'),
    String[1] $lvm_volume_group         = lookup('profile::openstack::eqiad1::cinder::lvm_volume_group'),
    ) {

    class { '::profile::openstack::base::cinder::volume':
        version                 => $version,
        rabbitmq_nodes          => $rabbitmq_nodes,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        region                  => $region,
        ceph_pool               => $ceph_pool,
        ceph_rbd_client_name    => $ceph_rbd_client_name,
        rabbit_pass             => $rabbit_pass,
        libvirt_rbd_cinder_uuid => $libvirt_rbd_cinder_uuid,
        backend_type            => $backend_type,
        backend_name            => $backend_name,
        lvm_volume_group        => $lvm_volume_group,
    }
}
