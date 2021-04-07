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
#
class ceph::config (
    Boolean                     $enable_libvirt_rbd,
    Boolean                     $enable_v2_messenger,
    Hash[String,Hash]           $mon_hosts,
    Stdlib::IP::Address         $cluster_network,
    Stdlib::IP::Address         $public_network,
    String                      $fsid,
    Optional[Hash[String,Hash]] $osd_hosts = {},
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
