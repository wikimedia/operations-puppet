class role::labs::nfsclient(
    $mode = 'hard',
) {

    $nfs_server = ipresolve('labstore.svc.eqiad.wmnet',4)
    $misc_nfs = ipresolve('labstore1003.eqiad.wmnet',4)

    labstore::nfs_mount { 'project':
        project    => $::labsproject,
        options    => ['rw', $mode],
        mount_path => '/data/project',
        share_path => "/project/${::labsproject}/project",
        server     => $nfs_server,
        block      => true,
    }

    labstore::nfs_mount { 'home':
        project    => $::labsproject,
        options    => ['rw', 'hard'],
        mount_path => '/home',
        share_path => "/project/${::labsproject}/home",
        server     => $nfs_server,
        block      => true,
    }

    labstore::nfs_mount { 'scratch':
        project    => $::labsproject,
        options    => ['rw', 'soft', 'timeo=100', 'retrans=3'],
        mount_path => '/data/scratch',
        server     => $nfs_server,
        share_path => '/scratch',
    }

    labstore::nfs_mount { 'dumps':
        project    => $::labsproject,
        options    => ['ro', 'soft', 'timeo=100', 'retrans=3'],
        mount_path => '/public/dumps',
        share_path => '/dumps',
        server     => $misc_nfs,
    }

    # ideally this is only on NFS enabled hosts in the future
    diamond::collector { 'Nfsiostat':
        source  => 'puppet:///modules/diamond/collector/nfsiostat.py',
        require => Package['diamond'],
    }
}
