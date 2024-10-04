# SPDX-License-Identifier: Apache-2.0
# README:
#  what is going on in this class is described in the upstream docs:
#  https://docs.ceph.com/en/latest/man/8/ceph-mds/
#
class ceph::mds (
    Stdlib::Unixpath       $data_dir,
    Ceph::Auth::ClientAuth $mds_auth,
) {
    ensure_packages(['ceph-mds'])

    $client = "mds.${::hostname}"

    if ! defined(Ceph::Auth::Keyring[$client]) {
        fail("missing ceph::auth::keyring[${client}], check hiera 'profile::cloudceph::auth::load_all::configuration'")
    }

    if defined(Ceph::Auth::Keyring['admin']) {
        Ceph::Auth::Keyring['admin'] -> Class['ceph::mds']
    } else {
        notify { 'ceph::mds: Admin keyring not defined, things might not work as expected.': }
    }

    $keyring_path = ceph::auth::get_keyring_path($client, $mds_auth['keyring_path'])

    # If the daemon hasn't been setup yet, first verify we can connect to the ceph cluster
    exec { 'ceph-mds-check':
        command => '/usr/bin/ceph -s',
        onlyif  => "/usr/bin/test ! -e ${keyring_path}",
    }
    if defined(Ceph::Auth::Keyring['admin']) {
        Ceph::Auth::Keyring['admin'] -> Exec['ceph-mds-check']
    }

    service { "ceph-mds@${::hostname}":
        ensure    => running,
        enable    => true,
        require   => Ceph::Auth::Keyring[$client],
        subscribe => File['/etc/ceph/ceph.conf'],
    }
}
