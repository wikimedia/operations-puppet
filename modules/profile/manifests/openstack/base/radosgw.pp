# radosgw packages and service.  The config is combined with glance/ceph config
#  and defined in profile::openstack::base::rbd_cloudcontrol
class profile::openstack::base::radosgw(
    String $version = lookup('profile::openstack::base::version'),
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

    ceph::keyring { "client.rgw.${::hostname}":
        ensure  => 'present',
        cap_mon => 'allow rw',
        cap_osd => 'allow rwx',
        mode    => '0440',
        keyring => "/etc/ceph/ceph.client.radosgw-${::hostname}.keyring",
    }
}
