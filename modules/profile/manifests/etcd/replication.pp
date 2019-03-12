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
# [*dst_url*] scheme:hostname:port combination of the target etcd instance
#             (namely the one receiving the replicated data from etcd mirror).
#             Default: http://localhost:2378
#
# [*src_port*] Client port of the origin etcd instance
#              (namely the one replicating data via etcd mirror).
#              Default: 2379
#
class profile::etcd::replication(
    $origin = hiera('profile::etcd::replication::origin'),
    $destination_path = hiera('profile::etcd::replication::destination_path'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    $active = hiera('profile::etcd::replication::active'),
    $dst_url = hiera('profile::etcd::replication::dst_url', 'http://localhost:2378'),
    $src_port = hiera('profile::etcd::replication::src_port', 2379),
) {
    require ::passwords::etcd
    $accounts = $::passwords::etcd::accounts
    # Replica is always from remote to local. This means only the local account
    # is needed.
    $resource_title = "${origin['path']}@${origin['cluster_name']}"

    $etcdmirror_web_port = 8000

    $hosts = fqdn_rotate($origin['servers'])
    etcdmirror::instance { $resource_title:
        src      => "https://${hosts[0]}:${src_port}",
        src_path => $origin['path'],
        dst      => $dst_url,
        dst_path => $destination_path,
        enable   => $active,
    }


    if $active {
        # Monitoring lag is less than 5 operations. TODO: take this from prometheus.
        monitoring::service{ 'etcd_replication_lag':
            description   => 'Etcd replication lag',
            check_command => "check_http_url_for_regexp_on_port!${::fqdn}!${etcdmirror_web_port}!/lag!'^(-[1-9]|[0-5][^0-9]+)'",
            critical      => true,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Etcd',
        }
    }

    # ferm for the prometheus exporter
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'etcdmirror_prometheus':
        proto  => 'tcp',
        port   => $etcdmirror_web_port,
        srange => $ferm_srange,
    }
}
