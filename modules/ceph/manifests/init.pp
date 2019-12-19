# Class: ceph
#
# This class manages the Ceph common packages and configuration
#
# Parameters
#    - $mon_hosts
#        Hash that defines the ceph monitor hosts, and public and private IPv4 information
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
class ceph (
    Boolean                     $enable_libvirt_rbd,
    Boolean                     $enable_v2_messenger,
    Hash[String,Hash]           $mon_hosts,
    Stdlib::IP::Address         $cluster_network,
    Stdlib::IP::Address         $public_network,
    Stdlib::Unixpath            $data_dir,
    String                      $fsid,
    Optional[Hash[String,Hash]] $osd_hosts = {},
) {
    group { 'ceph':
        ensure => present,
        system => true,
    }
    user { 'ceph':
        ensure     => present,
        gid        => 'ceph',
        shell      => '/usr/sbin/nologin',
        comment    => 'Ceph storage service',
        home       => $data_dir,
        managehome => false,
        system     => true,
        require    => Group['ceph'],
    }

    # Ceph common package used for all services and clients
    package { 'ceph-common':
        ensure  => present,
        require => User['ceph'],
    }

    # Ceph configuration file used for all services and clients
    file { '/etc/ceph/ceph.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('ceph/ceph.conf.erb'),
        require => Package['ceph-common'],
    }

    file { '/var/log/ceph':
        ensure => directory,
        mode   => '0755',
        owner  => 'ceph',
        group  => 'ceph',
    }

    if $enable_libvirt_rbd {
        # TODO work on libvirt dependencies
        package { 'python-rbd':
            ensure => present,
        }
        # Enable rbd support in qemu
        package { 'qemu-block-extra':
            ensure  => present,
        }

        # This directory contains qemu guest logs
        file { '/var/log/ceph/qemu':
            ensure => directory,
            mode   => '0755',
            owner  => 'libvirt-qemu',
            group  => 'libvirt-qemu',
        }

        file { '/var/run/ceph':
            ensure => directory,
            mode   => '0750',
            owner  => 'ceph',
            group  => 'libvirt-qemu',
        }

        # This directory is used for admin socket connections
        file { '/var/run/ceph/guests':
            ensure => directory,
            mode   => '0770',
            owner  => 'ceph',
            group  => 'libvirt-qemu',
        }
    } else {
        file { '/var/run/ceph':
            ensure => directory,
            mode   => '0770',
            owner  => 'ceph',
            group  => 'ceph',
        }
    }
}
