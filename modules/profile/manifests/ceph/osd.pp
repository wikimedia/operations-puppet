# Class: profile::ceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::ceph::osd(
    Array[Stdlib::Fqdn]            $mon_hosts     = lookup('profile::ceph::mon::hosts'),
    Array[Stdlib::IP::Address::V4] $mon_addrs     = lookup('profile::ceph::mon::addrs'),
    Stdlib::AbsolutePath           $admin_keyring = lookup('profile::ceph::admin_keyring'),
    Stdlib::Unixpath               $data_dir      = lookup('profile::ceph::data_dir'),
    String                         $admin_secret  = lookup('profile::ceph::admin_secret'),
    String                         $fsid          = lookup('profile::ceph::fsid'),
) {
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
