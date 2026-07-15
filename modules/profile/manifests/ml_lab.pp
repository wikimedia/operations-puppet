# SPDX-License-Identifier: Apache-2.0
# == Class: profile::ml_lab
#
# Mounts the shared CephFS 'home' filesystem on /home for ML Lab machines.
#
# The Ceph cluster fsid is resolved from Hiera (profile::ceph::fsid) so that
# the correct cluster is selected per datacenter. The 'ml_lab' portion of the
# device string is the Ceph client/auth name (see profile::ceph::client and the
# ml_lab role's selected_creds).
#
# Parameters:
#   $ceph_fs_id: The fsid of the Ceph cluster to mount from.
#
class profile::ml_lab (
    String $ceph_fs_id = lookup('profile::ceph::fsid'),
) {
    require profile::ceph::client

    file { '/home':
        ensure => directory,
    }

    mount { '/home':
        ensure  => mounted,
        device  => "ml_lab@${ceph_fs_id}.home=/",
        fstype  => 'ceph',
        options => 'rw,relatime',
        dump    => '0',
        pass    => '0',
        require => File['/home'],
    }
}
