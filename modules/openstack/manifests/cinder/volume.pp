# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::volume(
    $version,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String[1]           $db_user,
    String[1]           $db_pass,
    String[1]           $db_name,
    Stdlib::Fqdn        $db_host,
    String[1]           $region,
    String[1]           $ceph_pool,
    String[1]           $ceph_rbd_client_name,
    String[1]           $rabbit_user,
    String[1]           $rabbit_pass,
    String[1]           $libvirt_rbd_cinder_uuid,
    Array[String]       $all_backend_types,
    String[1]           $backend_type,
    String[1]           $backend_name,
    String[1]           $lvm_volume_group,
) {
    class { "openstack::cinder::volume::${version}":
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
        all_backend_types       => $all_backend_types,
        backend_type            => $backend_type,
        backend_name            => $backend_name,
        lvm_volume_group        => $lvm_volume_group,
    }

    service { 'cinder-volume':
        require => Package['cinder-volume'],
    }
}
