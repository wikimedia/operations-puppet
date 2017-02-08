class role::dataset::common {
    include ::standard
    include ::base::firewall

    ferm::service { 'nfs_rpc_mountd':
        proto  => 'tcp',
        port   => '32767',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_rpc_statd':
        proto  => 'tcp',
        port   => '32765',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
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
