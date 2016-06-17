# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    system::role { 'role::dataset::secondary':
        description => 'dataset secondary host',
    }

    $rsync = {
        'public' => true,
        'peers'  => true,
    }
    $grabs = {
    }
    $uploads = {
    }

    class { 'dataset':
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }

    ferm::service { 'nfs_rpc_mountd':
        proto  => 'tcp',
        port   => '32767',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_rpc_statd':
        proto  => 'tcp',
        port   => '32765',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$INTERNAL',
    }
}
