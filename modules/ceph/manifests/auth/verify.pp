# SPDX-License-Identifier: Apache-2.0
#
# Installs the script that compares the CephX keyring files on this host against the
# keys that the cluster holds. The script needs cluster admin credentials to run, so
# it goes in sbin.
class ceph::auth::verify {
    file { '/usr/local/sbin/verify-cephx-keys':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ceph/verify_cephx_keys.py',
    }
}
