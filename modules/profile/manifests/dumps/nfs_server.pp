class profile::dumps::nfs_server {
    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

    ferm::service { 'dumps_nfs':
        proto  => 'tcp',
        port   => '2049',
        srange => '$PRODUCTION_NETWORKS',
    }
}
