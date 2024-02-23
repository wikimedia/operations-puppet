# SPDX-License-Identifier: Apache-2.0
class profile::dumps::nfs(
    Hash $clients_all = lookup('dumps_nfs_clients'),
    String $clients_wanted = lookup('profile::dumps::nfs::clients_wanted'),
) {
    $path    = '/data'

    if ($clients_wanted == 'all') {
        $clients = {'generation' => pick($clients_all['snapshots'], []),
                    'public'     => pick($clients_all['other'], [])}
    } elsif ($clients_wanted == 'generation') {
        $clients = {'generation' => pick($clients_all['snapshots'], [])}
    } elsif ($clients_wanted == 'public') {
        $clients = {'public' => pick($clients_all['other'], [])}
    } else {
        $clients = {}
    }

    $lockd_udp       = 32768
    $lockd_tcp       = 32769
    $mountd_port     = 32767
    $statd_port      = 32765
    $statd_out       = 32766
    $portmapper_port = 111

    class { '::dumps::nfs':
        clients     => $clients,
        path        => $path,
        lockd_udp   => $lockd_udp,
        lockd_tcp   => $lockd_tcp,
        mountd_port => $mountd_port,
        statd_port  => $statd_port,
        statd_out   => $statd_out,
    }

    include ::network::constants

    firewall::service { 'dumps_nfs':
        proto    => 'tcp',
        port     => 2049,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_rpc_mountd':
        proto    => 'tcp',
        port     => $mountd_port,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_rpc_statd':
        proto    => 'tcp',
        port     => $statd_port,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_portmapper_udp':
        proto    => 'udp',
        port     => $portmapper_port,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_portmapper_tcp':
        proto    => 'tcp',
        port     => $portmapper_port,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_lockd_udp':
        proto    => 'udp',
        port     => $lockd_udp,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    firewall::service { 'nfs_lockd_tcp':
        proto    => 'tcp',
        port     => $lockd_tcp,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    class { '::dumps::monitoring': }
}
