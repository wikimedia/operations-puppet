# Class: profile::ceph::client:rbd_libvirt
#
# This profile will configure clients for connecting to Ceph rados block storage
# using the native kernel driver or librbd. This includes some extras for integration
# with nova/libvirt/qemu
class profile::ceph::client::rbd_libvirt(
    Boolean             $enable_v2_messenger     = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]   $mon_hosts               = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]   $osd_hosts               = lookup('profile::ceph::osd::hosts'),
    Stdlib::IP::Address $cluster_network         = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address $public_network          = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath    $data_dir                = lookup('profile::ceph::data_dir'),
    String              $client_name             = lookup('profile::ceph::client::rbd::client_name'),
    String              $cinder_client_name      = lookup('profile::ceph::client::rbd::cinder_client_name'),
    String              $fsid                    = lookup('profile::ceph::fsid'),
    String              $keydata                 = lookup('profile::ceph::client::rbd::keydata'),
    String              $cinder_keydata          = lookup('profile::ceph::client::rbd::cinder_client_keydata'),
    String              $libvirt_rbd_uuid        = lookup('profile::ceph::client::rbd::libvirt_rbd_uuid'),
    String              $libvirt_rbd_cinder_uuid = lookup('profile::ceph::client::rbd::libvirt_rbd_cinder_uuid'),
    String              $ceph_repository_component  = lookup('profile::ceph::ceph_repository_component',  { 'default_value' => 'thirdparty/ceph-nautilus-buster' })
) {

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_network     => $cluster_network,
        enable_libvirt_rbd  => true,
        enable_v2_messenger => $enable_v2_messenger,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        public_network      => $public_network,
    }

    openstack::nova::libvirt::secret { 'nova-compute':
        keydata      => $keydata,
        client_name  => $client_name,
        libvirt_uuid => $libvirt_rbd_uuid,
    }
    openstack::nova::libvirt::secret { 'nova-compute-cinder':
        keydata      => $cinder_keydata,
        client_name  => $cinder_client_name,
        libvirt_uuid => $libvirt_rbd_cinder_uuid,
    }

    # TODO: cleanup old files
    file { '/etc/ceph/libvirt-cinder-secret.xml':
        ensure => absent,
    }
    file { '/etc/ceph/libvirt-secret.xml':
        ensure => absent,
    }

    class { 'prometheus::node_pinger':
        nodes_to_ping => $osd_hosts.keys() + $mon_hosts.keys(),
    }
}
