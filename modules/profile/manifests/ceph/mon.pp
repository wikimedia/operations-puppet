# Class: profile::ceph::mon
#
# This profile configures Ceph monitor hosts with the mon and mgr daemons
class profile::ceph::mon(
    Hash[String,Hash]    $mon_hosts       = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]    $osd_hosts       = lookup('profile::ceph::osd::hosts'),
    Stdlib::AbsolutePath $admin_keyring   = lookup('profile::ceph::admin_keyring'),
    Stdlib::IP::Address  $cluster_network = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address  $public_network  = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    String               $admin_keydata   = lookup('profile::ceph::admin_keydata'),
    String               $fsid            = lookup('profile::ceph::fsid'),
    String               $mon_keydata     = lookup('profile::ceph::mon::keydata'),
) {
    include ::network::constants
    # Limit the client connections to the hypervisors in eqiad and codfw
    $client_networks = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-hosts1-b-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['codfw']['private']['labs-hosts1-b-codfw']['ipv4'],
    ]

    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }

    $ferm_srange = join(concat($mon_addrs, $osd_addrs, $client_networks), ' ')
    ferm::service { 'ceph_mgr_v2':
        proto  => 'tcp',
        port   => 6800,
        srange => "(${ferm_srange})",
        before => Class['ceph'],
    }
    ferm::service { 'ceph_mgr_v1':
        proto  => 'tcp',
        port   => 6801,
        srange => "(${ferm_srange})",
        before => Class['ceph'],
    }
    ferm::service { 'ceph_mon_peers_v1':
        proto  => 'tcp',
        port   => 6789,
        srange => "(${ferm_srange})",
        before => Class['ceph'],
    }
    ferm::service { 'ceph_mon_peers_v2':
        proto  => 'tcp',
        port   => 3300,
        srange => "(${ferm_srange})",
        before => Class['ceph'],
    }

    if os_version('debian == buster') {
        apt::repository { 'thirdparty-ceph-nautilus-buster':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'thirdparty/ceph-nautilus-buster',
            source     => false,
            before     => Class['ceph'],
        }
    }

    class { 'ceph':
        cluster_network     => $cluster_network,
        data_dir            => $data_dir,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => true,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        osd_hosts           => $osd_hosts,
        public_network      => $public_network,
    }

    class { 'ceph::admin':
        admin_keyring => $admin_keyring,
        admin_keydata => $admin_keydata,
        data_dir      => $data_dir,
    }

    Class['ceph::mon'] -> Class['ceph::mgr']
    class { 'ceph::mon':
        admin_keyring => $admin_keyring,
        data_dir      => $data_dir,
        fsid          => $fsid,
        mon_keydata   => $mon_keydata,
    }

    class { 'ceph::mgr':
        data_dir => $data_dir,
    }
}
