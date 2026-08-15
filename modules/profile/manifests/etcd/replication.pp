# == Class profile::etcd::replication
#
# Run replication from remote clusters to the local one.
#
# == Parameters
#
# [*origin*] Hash with information on the source in the form:
#   {
#        'cluster_name' => 'test-cluster', 'path' => '/conftool',
#        'servers' => ['server1', 'server2'...],
#    }
#
# [*destination_path*] Destination path on the local machine
#
# [*active*] If replication is active. For now, only one server per cluster
#
# [*dst_url*] scheme://hostname:port combination of the target etcd instance
#             (namely the one receiving the replicated data from etcd mirror).
#             Default: https://FDQN:2379 where FQDN is that of the host where
#                      etcd mirror is running.
#
# [*src_port*] Client port of the origin etcd instance
#              (namely the one replicating data via etcd mirror).
#              Default: 2379
#
class profile::etcd::replication(
    Hash $origin = lookup('profile::etcd::replication::origin'),
    Stdlib::Unixpath $destination_path = lookup('profile::etcd::replication::destination_path'),
    Boolean $active = lookup('profile::etcd::replication::active'),
    Optional[Stdlib::Httpurl] $dst_url = lookup('profile::etcd::replication::dst_url', {'default_value' => undef}),
    Stdlib::Port $src_port = lookup('profile::etcd::replication::src_port', {'default_value' => 2379})
) {
    require ::passwords::etcd
    $accounts = $::passwords::etcd::accounts
    # Replica is always from remote to local. This means only the local account
    # is needed.
    $resource_title = "${origin['path']}@${origin['cluster_name']}"
    # If no destination is specified, default to https to the standard
    # client port on the mirror host.
    $destination_url = $dst_url ? {
        undef => "https://${facts['networking']['fqdn']}:2379",
        default => $dst_url,
    }

    $hosts = fqdn_rotate($origin['servers'])
    etcdmirror::instance { $resource_title:
        src                   => "https://${hosts[0]}:${src_port}",
        src_path              => $origin['path'],
        src_ignore_keys_regex => $origin['ignore_keys_regex'],
        dst                   => $destination_url,
        dst_path              => $destination_path,
        enable                => $active,
    }
}
