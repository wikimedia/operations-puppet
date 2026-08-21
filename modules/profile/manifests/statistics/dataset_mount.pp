# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::dataset_mount
#
class profile::statistics::dataset_mount {
    # Define the dumpsgen user with uid and gid of 400
    # This is required in order to mount the NFS directories cleanly
    class { 'dumpsuser': }

    class { 'profile::dumps::nfs_client':
        ensure => present,
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
