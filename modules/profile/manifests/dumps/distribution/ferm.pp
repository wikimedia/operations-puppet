# Setup ferm rules for internal and external clients -
# By default the resolve() function in ferm performs only an IPv4/A DNS
# lookup. It fails if a host only has an IPv6 address. Ferm also provides
# a AAAA lookup mode for IPv6 addresses, but this equally fails if only
# an IPv4 address is present.
class profile::dumps::distribution::ferm(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
) {
    $rsync_clients_ipv4_ferm = join(concat($rsync_clients['ipv4']['internal'], $rsync_clients['ipv4']['external']), ' ')
    $rsync_clients_ipv6_ferm = join(concat($rsync_clients['ipv6']['internal'], $rsync_clients['ipv6']['external']), ' ')

    ferm::service {'dumps_rsyncd_ipv4':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv4_ferm}))",
    }

    ferm::service {'dumps_rsyncd_ipv6':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv6_ferm}),AAAA)",
    }

    ferm::service { 'labstore_analytics_nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_nfs_service':
        proto  => 'tcp',
        port   => '2049',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_statd_tcp':
        proto  => 'tcp',
        port   => '55659',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_statd_udp':
        proto  => 'udp',
        port   => '55659',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_mountd':
        proto  => 'tcp',
        port   => '38466',
        srange => '$ANALYTICS_NETWORKS',
    }
}
