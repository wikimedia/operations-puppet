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
# [*accounts*] Accounts on the local cluster, 'root' must be defined
#
# [*active*] If replication is active. For now, only one server per cluster
#
class profile::etcd::replication(
    $origin = hiera('profile::etcd::replication::origin'),
    $destination_path = hiera('profile::etcd::replication::destination_path'),
    $accounts = hiera('profile::etcd::tlsproxy::accounts'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    $active = hiera('profile::etcd::replication::active'),
) {
    require ::passwords::etcd
    $accounts = $::passwords::etcd::accounts
    # Replica is always from remote to local. This means only the local account
    # is needed.
    $resource_title = "${origin['path']}@${origin['cluster_name']}"

    $etcdmirror_web_port = 8000

    $hosts = fqdn_rotate($origin['servers'])
    etcdmirror::instance { $resource_title:
        src      => "https://${hosts[0]}:2379",
        src_path => $origin['path'],
        dst      => "https://root:${accounts['root']}@${::fqdn}:2379",
        dst_path => $destination_path,
        enable   => $active,
    }


    if $active {
        # Monitoring lag is less than 5 operations. TODO: take this from prometheus.
        monitoring::service{ 'etcd_replication_lag':
            description   => 'Etcd replication lag',
            check_command => "check_http_url_for_regexp_on_port!${::fqdn}!${etcdmirror_web_port}!/lag!'^(-1|[0-5])[^0-9]+'",
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
