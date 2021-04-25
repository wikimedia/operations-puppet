# Class: ceph::config
#
# This class manages the Ceph common packages and configuration
#
# Parameters
#    - $mon_hosts
#        Hash that defines the ceph monitor host's public and private IPv4 information
#    - $fsid
#        Ceph filesystem ID
#    - $enable_v2_messenger
#        Enables Ceph messenger version 2 ( >= Nautilus release)
#    - $enable_libvirt_rbd
#        Configure Ceph for libvirt based RBD clients
#        Currently requires openstack::nova::compute::service::ocata::stretch
#    - $osd_hosts [Optional]
#        Hash that defines the ceph object storage hosts, and public and private IPv4 information
#    - $radosgw_port [Optional]
#        Listen port for the rados gateway. Gateway will only be configured if this is set.
#    - $keystone_internal_uri [Optional]
#        URI for internal keystone service. Only used if radosgw_port is set.
#    - $radosgw_service_user [Optional]
#        Name of radosgw service user (probably 'swift'). Only used if radosgw_port is set.
#    - $radosgw_service_user_project [Optional]
#        Project for radosgw service user (probably 'service'). Only used if radosgw_port is set.
#    - $radosgw_service_user_password [Optional]
#        Password for radosgw service user. Only used if radosgw_port is set.
#
class ceph::config (
    Boolean                     $enable_libvirt_rbd,
    Boolean                     $enable_v2_messenger,
    Hash[String,Hash]           $mon_hosts,
    Stdlib::IP::Address         $cluster_network,
    Stdlib::IP::Address         $public_network,
    String                      $fsid,
    Optional[Hash[String,Hash]] $osd_hosts = {},
    Optional[Stdlib::Port]      $radosgw_port = 0,
    Optional[String]            $keystone_internal_uri = '',
    Optional[String]            $radosgw_service_user = '',
    Optional[String]            $radosgw_service_user_project = '',
    Optional[String]            $radosgw_service_user_pass = '',
) {

    Class['ceph::common'] -> Class['ceph::config']

    # Ceph configuration file used for all services and clients
    file { '/etc/ceph/ceph.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('ceph/ceph.conf.erb'),
        require => Package['ceph-common'],
    }

    if $enable_libvirt_rbd {
        ensure_packages([
          'python-rbd',
          # Enable rbd support in qemu
          'qemu-block-extra',
        ])

        # This directory contains qemu guest logs
        file { '/var/log/ceph/qemu':
            ensure => directory,
            mode   => '0755',
            owner  => 'libvirt-qemu',
            group  => 'libvirt-qemu',
        }

        # Allow libvirt-qemu to access the Ceph admin socket
        File<|title == '/var/run/ceph'|> {
            group  => 'libvirt-qemu',
        }

        file { '/var/run/ceph/guests':
            ensure => directory,
            mode   => '0770',
            owner  => 'ceph',
            group  => 'libvirt-qemu',
        }
    }
}
