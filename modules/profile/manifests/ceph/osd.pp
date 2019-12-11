# Class: profile::ceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::ceph::osd(
    Array[Stdlib::Fqdn]            $mon_hosts     = lookup('profile::ceph::mon::hosts'),
    Array[Stdlib::IP::Address::V4] $mon_addrs     = lookup('profile::ceph::mon::addrs'),
    Array[Stdlib::IP::Address::V4] $osd_addrs     = lookup('profile::ceph::osd::addrs'),
    Stdlib::AbsolutePath           $admin_keyring = lookup('profile::ceph::admin_keyring'),
    Stdlib::Unixpath               $data_dir      = lookup('profile::ceph::data_dir'),
    String                         $admin_secret  = lookup('profile::ceph::admin_secret'),
    String                         $fsid          = lookup('profile::ceph::fsid'),
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
    $ferm_srange = join(concat($mon_addrs, $osd_addrs, $client_networks), ' ')
    ferm::service { 'ceph_osd_range':
        proto  => 'tcp',
        port   => '6800:7100',
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
        data_dir  => $data_dir,
        fsid      => $fsid,
        mon_addrs => $mon_addrs,
        mon_hosts => $mon_hosts,
    }

    class { 'ceph::admin':
        admin_keyring => $admin_keyring,
        admin_secret  => $admin_secret,
        data_dir      => $data_dir,
    }

}
