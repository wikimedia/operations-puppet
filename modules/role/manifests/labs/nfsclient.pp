class role::labs::nfsclient(
    $mode = 'hard',
) {

    $nfs_server = 'labstore.svc.eqiad.wmnet'
    $misc_nfs = 'labstore1003.eqiad.wmnet'

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
        options    => ['rw', $mode],
        mount_path => '/data/scratch',
        server     => $nfs_server,
        share_path => '/scratch',
    }

    labstore::nfs_mount { 'dumps':
        project    => $::labsproject,
        options    => ['ro', $mode],
        mount_path => '/public/dumps',
        share_path => '/dumps',
        server     => $misc_nfs,
    }
}
