# Setup ferm rules for rsync - currently this is only for backup
class profile::wmcs::nfs::rsync::ferm(
    Array[Stdlib::Host] $secondary_nfs_servers = lookup('secondary_nfs_servers'),
) {
    $rsync_hosts = join($secondary_nfs_servers, ' ')
    ferm::service {'secondary_rsyncd':
        port   => '873',
        proto  => 'tcp',
        srange => "(@resolve((${rsync_hosts})) @resolve((${rsync_hosts}), AAAA))",
    }
}