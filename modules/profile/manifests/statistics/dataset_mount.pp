# == Class profile::statistics::dataset_mount
#
class profile::statistics::dataset_mount (
    $dumps_servers       = lookup('dumps_dist_nfs_servers'),
    $dumps_active_server = lookup('dumps_dist_active_web'),
){

    $hosts_with_dataset_mount = ['stat1004', 'stat1005', 'stat1006', 'stat1007', 'an-launcher1001']

    if $::hostname in $hosts_with_dataset_mount {
        class { '::statistics::dataset_mount':
            dumps_servers       => $dumps_servers,
            dumps_active_server => $dumps_active_server,
        }
    }
}