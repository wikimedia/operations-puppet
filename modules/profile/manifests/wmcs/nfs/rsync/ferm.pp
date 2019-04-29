# Setup ferm rules for rsync - currently this is only for backup
class profile::wmcs::nfs::rsync::ferm(
    $rsync_clients = hiera('secondary_nfs_servers'),
) {
    ferm::service {'dumps_rsyncd_ipv4':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients}))",
    }

    ferm::service {'dumps_rsyncd_ipv6':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients}),AAAA)",
    }
}