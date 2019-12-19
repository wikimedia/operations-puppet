# Class: profile::ceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::ceph::osd(
    Hash[String,Hash]    $mon_hosts       = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]    $osd_hosts       = lookup('profile::ceph::osd::hosts'),
    Stdlib::AbsolutePath $admin_keyring   = lookup('profile::ceph::admin_keyring'),
    Stdlib::IP::Address  $cluster_network = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address  $public_network  = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    String               $admin_keydata   = lookup('profile::ceph::admin_keydata'),
    String               $fsid            = lookup('profile::ceph::fsid'),
) {
    include ::network::constants
    # Limit the client connections to the hypervisors in eqiad and codfw
    $client_networks = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-hosts1-b-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['codfw']['private']['labs-hosts1-b-codfw']['ipv4'],
    ]

    # Each ceph osd server runs multiple daemons, each daemon listens on 6 ports
    # The ports can range anywhere between 6800 and 7100. This can be controlled
    # with the `ms bind port min` and `ms bind port max` ceph config parameters.

    # The cluster interface is used for OSD data replication and heartbeat network traffic
    interface::ip { 'osd-cluster':
        interface => $osd_hosts["$::fqdn"]['cluster']['iface'],
        address   => $osd_hosts["$::fqdn"]['cluster']['addr'],
        prefixlen => $osd_hosts["$::fqdn"]['cluster']['prefix'],
        before    => Class['ceph'],
    }
    $ferm_cluster_srange = join($osd_hosts.map | $key, $value | { $value['cluster']['addr'] }, ' ')
    ferm::service { 'ceph_osd_cluster_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_cluster_srange})",
        drange => $osd_hosts["$::fqdn"]['cluster']['addr'],
        before => Class['ceph'],
    }

    # The public network is used for communication between Ceph serivces and client traffic
    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }
    $ferm_public_srange = join(concat($mon_addrs, $osd_addrs, $client_networks), ' ')
    ferm::service { 'ceph_osd_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_public_srange})",
        drange => $osd_hosts["$::fqdn"]['public']['addr'],
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
}
