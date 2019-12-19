# Class: profile::ceph::client:rbd
#
# This profile will configure clients for connecting to Ceph rados block storage
# using the native kernel driver or librbd
class profile::ceph::client::rbd(
    Boolean             $enable_v2_messenger = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]   $mon_hosts           = lookup('profile::ceph::mon::hosts'),
    Stdlib::IP::Address $cluster_network     = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address $public_network      = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath    $data_dir            = lookup('profile::ceph::data_dir'),
    String              $client_name         = lookup('profile::ceph::client::rbd::client_name'),
    String              $fsid                = lookup('profile::ceph::fsid'),
    String              $keydata             = lookup('profile::ceph::client::rbd::keydata'),
    String              $keyfile_group       = lookup('profile::ceph::client::rbd::keyfile_group'),
    String              $keyfile_owner       = lookup('profile::ceph::client::rbd::keyfile_owner'),
    String              $libvirt_rbd_uuid    = lookup('profile::ceph::client::rbd::libvirt_rbd_uuid'),
) {

    class { 'ceph':
        cluster_network     => $cluster_network,
        data_dir            => $data_dir,
        enable_libvirt_rbd  => true,
        enable_v2_messenger => $enable_v2_messenger,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        public_network      => $public_network,
    }

    # The keydata used in this step is pre-created on one of the ceph mon hosts
    # typically with the 'ceph auth get-or-create' command
    file { "/etc/ceph/ceph.client.${client_name}.keyring":
        ensure    => present,
        mode      => '0440',
        owner     => $keyfile_owner,
        group     => $keyfile_group,
        content   => "[client.${client_name}]\n        key = ${keydata}\n",
        show_diff => false,
        require   => Package['ceph-common'],
    }
    #TODO libvirt dependency
    file { '/etc/ceph/libvirt-secret.xml':
        ensure    => present,
        mode      => '0400',
        owner     => 'root',
        group     => 'root',
        content   => template('profile/ceph/libvirt-secret.xml.erb'),
        show_diff => false,
        require   => Package['ceph-common'],
    }

    # Add the keydata to libvirt, which is referenced by nova-compute in nova.conf
    exec { 'check-virsh-secret':
        command   => '/usr/bin/virsh secret-define --file /etc/ceph/libvirt-secret.xml',
        unless    => "/usr/bin/virsh secret-list | grep -q ${libvirt_rbd_uuid}",
        logoutput => false,
        require   => File['/etc/ceph/libvirt-secret.xml'],
    }
    exec { 'set-virsh-secret':
        command   => "/usr/bin/virsh secret-set-value --secret ${libvirt_rbd_uuid} --base64 ${keydata}",
        unless    => "/usr/bin/virsh secret-get-value --secret ${libvirt_rbd_uuid} | grep -q ${keydata}",
        logoutput => false,
        require   => Exec['check-virsh-secret'],
    }
}
