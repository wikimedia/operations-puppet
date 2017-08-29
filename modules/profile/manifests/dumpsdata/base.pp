class profile::dumpsdata::base(
    $clients = hiera('dumps_clients_snapshots'),
) {
    $mountd_port     = '32767'
    $statd_port      = '32765'
    $statd_out       = '32766'
    $portmapper_port = '111'
    $lockd_udp       = '32768'
    $lockd_tcp       = '32769'

    class { '::dumpsnfs':
        clients     => $clients,
        statd_port  => $statd_port,
        statd_out   => $statd_out,
        lockd_udp   => $lockd_udp,
        lockd_tcp   => $lockd_tcp,
        mountd_port => $mountd_port,
    }

    class { '::base::firewall': }

    ferm::service { 'nfs_rpc_mountd':
        proto  => 'tcp',
        port   => $mountd_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_rpc_statd':
        proto  => 'tcp',
        port   => $statd_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => $portmapper_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => $portmapper_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_lockd_udp':
        proto  => 'udp',
        port   => $lockd_udp,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_lockd_tcp':
        proto  => 'tcp',
        port   => $lockd_tcp,
        srange => '$PRODUCTION_NETWORKS',
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

    class { '::dumpsuser': }

    class { '::dumpsdirs':
        user  => $dumpsuser::user,
        group => $dumpsuser::group,
    }
}
