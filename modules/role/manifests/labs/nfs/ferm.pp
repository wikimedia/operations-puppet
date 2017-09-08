# Common ferm class for labstore servers.

class role::labs::nfs::ferm {
    ferm::service { 'labstore_nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'labstore_nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'labstore_nfs_rpc_statd_tcp':
        proto  => 'tcp',
        port   => '55659',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'labstore_nfs_rpc_statd_udp':
        proto  => 'udp',
        port   => '55659',
        srange => '$LABS_NETWORKS',
    }
}
