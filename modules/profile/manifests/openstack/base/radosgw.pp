# radosgw packages and service.  The config is combined with glance/ceph config
#  and defined in profile::openstack::base::rbd_cloudcontrol
class profile::openstack::base::radosgw(
    String $version = lookup('profile::openstack::base::version'),
    String $ceph_client_keydata = lookup('profile::openstack::base::radosgw::client_keydata'),
    ) {

    class { '::openstack::radosgw::service':
        version => $version,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'radosgw_api':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (8080) ACCEPT;",
    }

    # The keydata used in this step is pre-created on one of the ceph mon hosts
    # typically with the 'ceph auth get-or-create' command
    file { '/etc/ceph/ceph.client.radosgw.keyring':
        ensure    => present,
        mode      => '0440',
        owner     => ceph,
        group     => ceph,
        content   => "[client.rgw.${::hostname}]\n        key = ${ceph_client_keydata}\n",
        show_diff => false,
        require   => Package['ceph-common'],
    }
}
