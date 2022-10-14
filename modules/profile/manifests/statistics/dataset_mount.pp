# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::dataset_mount
#
class profile::statistics::dataset_mount (
    $dumps_servers       = lookup('dumps_dist_nfs_servers'),
    $dumps_active_server = lookup('dumps_dist_active_web'),
){
    # Define the dumpsgen user with uid and gid of 400
    # This is required in order to mount the NFS directories cleanly
    class { 'dumpsuser': }

    class { 'statistics::dataset_mount':
        dumps_servers       => $dumps_servers,
        dumps_active_server => $dumps_active_server,
    }
}
