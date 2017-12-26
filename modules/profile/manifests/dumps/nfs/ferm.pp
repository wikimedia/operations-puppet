class profile::dumps::nfs::ferm {
    include ::network::constants

    $mountd_port     = '32767'
    $statd_port      = '32765'
    $statd_out       = '32766'
    $portmapper_port = '111'

    ferm::service { 'dumps_nfs':
        proto  => 'tcp',
        port   => '2049',
        srange => '$PRODUCTION_NETWORKS',
    }

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
        port   => '32768',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_lockd_tcp':
        proto  => 'tcp',
        port   => '32769',
        srange => '$PRODUCTION_NETWORKS',
    }


}
