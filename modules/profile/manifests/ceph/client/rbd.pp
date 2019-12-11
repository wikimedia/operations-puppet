# Class: profile::ceph::client:rbd
#
# This profile configures the client to access Ceph rados block storage
class profile::ceph::client::rbd(
    Array[Stdlib::Fqdn]            $mon_hosts     = lookup('profile::ceph::mon::hosts'),
    Array[Stdlib::IP::Address::V4] $mon_addrs     = lookup('profile::ceph::mon::addrs'),
    Stdlib::Unixpath               $data_dir      = lookup('profile::ceph::data_dir'),
    String                         $client_name   = lookup('profile::ceph::client::rbd::client_name'),
    String                         $fsid          = lookup('profile::ceph::fsid'),
    String                         $keydata       = lookup('profile::ceph::client::rbd::keydata'),
    String                         $keyfile_group = lookup('profile::ceph::client::rbd::keyfile_group'),
    String                         $keyfile_owner = lookup('profile::ceph::client::rbd::keyfile_owner'),
) {

    class { 'ceph':
        data_dir  => $data_dir,
        fsid      => $fsid,
        mon_addrs => $mon_addrs,
        mon_hosts => $mon_hosts,
    }

    package { 'python-rbd':
        ensure  => present,
    }

    # The keydata used in this step is precreated on one of the ceph mon hosts
    # typically with the 'ceph auth get-or-create' command
    file { "/etc/ceph/ceph.client.${client_name}":
        ensure  => present,
        mode    => '0440',
        owner   => $keyfile_owner,
        group   => $keyfile_group,
        content => "[client.${name}]\n        key = ${keydata}",
        require => Package['ceph-common'],
    }
}
