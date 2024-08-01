# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::cinder::volume(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    String $region                      = lookup('profile::openstack::base::region'),
    String $db_user                     = lookup('profile::openstack::base::cinder::db_user'),
    String $db_name                     = lookup('profile::openstack::base::cinder::db_name'),
    String $db_pass                     = lookup('profile::openstack::base::cinder::db_pass'),
    Stdlib::Fqdn $db_host               = lookup('profile::openstack::base::cinder::db_host'),
    String $ceph_pool                   = lookup('profile::openstack::base::cinder::ceph_pool'),
    String $rabbit_user                 = lookup('profile::openstack::base::cinder::rabbit_user'),
    String $rabbit_pass                 = lookup('profile::openstack::base::cinder::rabbit_pass'),
    String $libvirt_rbd_cinder_uuid     = lookup('profile::cloudceph::client::rbd::libvirt_rbd_cinder_uuid'),
    String $ceph_rbd_client_name        = lookup('profile::openstack::base::cinder::ceph_rbd_client_name'),
    Array[String] $all_backend_names    = lookup('profile::openstack::base::cinder::all_backend_names'),
    String[1] $backend_type             = lookup('profile::openstack::base::cinder::backend_type'),
    String[1] $backend_name             = lookup('profile::openstack::base::cinder::backend_name'),
    String[1] $lvm_volume_group         = lookup('profile::openstack::base::cinder::lvm_volume_group'),
    ) {

    class { '::openstack::cinder::volume':
        version                 => $version,
        rabbitmq_nodes          => $rabbitmq_nodes,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        region                  => $region,
        ceph_pool               => $ceph_pool,
        ceph_rbd_client_name    => $ceph_rbd_client_name,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        libvirt_rbd_cinder_uuid => $libvirt_rbd_cinder_uuid,
        all_backend_names       => $all_backend_names,
        backend_type            => $backend_type,
        backend_name            => $backend_name,
        lvm_volume_group        => $lvm_volume_group,
    }
}
