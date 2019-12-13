# Class: profile::ceph::client:rbd
#
# This profile will configure clients for connecting to Ceph rados block storage
# using the native kernel driver or librbd
class profile::ceph::client::rbd(
    Array[Stdlib::Fqdn]            $mon_hosts           = lookup('profile::ceph::mon::hosts'),
    Array[Stdlib::IP::Address::V4] $mon_addrs           = lookup('profile::ceph::mon::addrs'),
    Boolean                        $enable_libvirt_rbd  = lookup('profile::ceph::client::rbd::enable_libvirt_rbd'),
    Boolean                        $enable_v2_messenger = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Stdlib::Unixpath               $data_dir            = lookup('profile::ceph::data_dir'),
    String                         $client_name         = lookup('profile::ceph::client::rbd::client_name'),
    String                         $fsid                = lookup('profile::ceph::fsid'),
    String                         $keydata             = lookup('profile::ceph::client::rbd::keydata'),
    String                         $keyfile_group       = lookup('profile::ceph::client::rbd::keyfile_group'),
    String                         $keyfile_owner       = lookup('profile::ceph::client::rbd::keyfile_owner'),
) {

    class { 'ceph':
        data_dir            => $data_dir,
        enable_libvirt_rbd  => $enable_libvirt_rbd,
        enable_v2_messenger => $enable_v2_messenger,
        fsid                => $fsid,
        mon_addrs           => $mon_addrs,
        mon_hosts           => $mon_hosts,
    }

    # The keydata used in this step is precreated on one of the ceph mon hosts
    # typically with the 'ceph auth get-or-create' command
    file { "/etc/ceph/ceph.client.${client_name}.keyring":
        ensure  => present,
        mode    => '0440',
        owner   => $keyfile_owner,
        group   => $keyfile_group,
        content => "[client.${client_name}]\n        key = ${keydata}\n",
        require => Package['ceph-common'],
    }
}
