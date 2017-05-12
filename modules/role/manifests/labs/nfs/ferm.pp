# Common ferm class for labstore servers.

class role::labs::nfs::ferm {
    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$LABS_NETWORKS',
    }
}
