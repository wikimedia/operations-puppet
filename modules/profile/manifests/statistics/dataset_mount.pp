# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::dataset_mount
#
class profile::statistics::dataset_mount (
    Boolean $dumps_use_nfs_lb = lookup('dumps_use_nfs_lb', { 'default_value' => false }),
    Array[Stdlib::Host] $dumps_servers = lookup('dumps_dist_nfs_servers'),
    Stdlib::Host $dumps_active_server = lookup('dumps_dist_active_web'),
){
    # Define the dumpsgen user with uid and gid of 400
    # This is required in order to mount the NFS directories cleanly
    class { 'dumpsuser': }

    # Temporary for partial rollout, this branch will be removed
    if ! $dumps_use_nfs_lb {
        class { 'statistics::dataset_mount':
            dumps_servers       => $dumps_servers,
            dumps_active_server => $dumps_active_server,
            ensure              => present,
        }

        class { 'profile::dumps::nfs_client':
            ensure => absent,
        }
    } else {
        # Mounts xmldatadumps ro at canonical /mnt/nfs/dumps
        class { 'profile::dumps::nfs_client':
            ensure => present,
        }

        class { 'statistics::dataset_mount':
            dumps_servers       => $dumps_servers,
            dumps_active_server => $dumps_active_server,
            ensure              => absent,
        }

        file { ['/mnt/data',
                '/mnt/data/xmldatadumps/']:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        file { '/mnt/data/xmldatadumps/public':
            ensure  => 'link',
            target  => '/mnt/nfs/dumps',
            require => Mount['/mnt/nfs/dumps'],
        }
    }
}
