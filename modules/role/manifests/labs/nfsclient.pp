class role::labs::nfsclient(
    $mode = 'hard',
    $lookupcache = 'none',
) {

    labstore::nfs_mount { 'project-on-labstoresvc':
        mount_name  => 'project',
        project     => $::labsproject,
        options     => ['rw', $mode],
        mount_path  => '/data/project',
        share_path  => "/project/${::labsproject}/project",
        server      => 'labstore.svc.eqiad.wmnet',
        block       => true,
        lookupcache => $lookupcache,
    }

    labstore::nfs_mount { 'home-on-labstoresvc':
        mount_name  => 'home',
        project     => $::labsproject,
        options     => ['rw', 'hard'],
        mount_path  => '/home',
        share_path  => "/project/${::labsproject}/home",
        server      => 'labstore.svc.eqiad.wmnet',
        block       => true,
        lookupcache => $lookupcache,
    }

    if $::labsproject == 'maps' {
        labstore::nfs_mount { 'maps-on-labstore1003':
            mount_name  => 'maps',
            project     => $::labsproject,
            options     => ['rw', 'soft', 'timeo=300', 'retrans=3'],
            mount_path  => '/mnt/nfs/labstore1003-maps',
            server      => 'labstore1003.eqiad.wmnet',
            share_path  => '/maps',
            lookupcache => $lookupcache,
        }
    }

    labstore::nfs_mount { 'scratch-on-labstoresvc':
        ensure      => absent,
        mount_name  => 'scratch',
        project     => $::labsproject,
        options     => ['rw', 'soft', 'timeo=300', 'retrans=3'],
        mount_path  => '/data/scratch',
        server      => 'labstore.svc.eqiad.wmnet',
        share_path  => '/scratch',
        lookupcache => $lookupcache,
    }

    labstore::nfs_mount { 'scratch-on-labstore1003':
        mount_name  => 'scratch',
        project     => $::labsproject,
        options     => ['rw', 'soft', 'timeo=300', 'retrans=3'],
        mount_path  => '/mnt/nfs/labstore1003-scratch',
        server      => 'labstore1003.eqiad.wmnet',
        share_path  => '/scratch',
        lookupcache => $lookupcache,
    }

    if mount_nfs_volume($::labsproject, 'scratch') {
        file { '/data/scratch':
            ensure  => 'link',
            target  => '/mnt/nfs/labstore1003-scratch',
            require => [Labstore::Nfs_mount['scratch-on-labstoresvc'],
                        Labstore::Nfs_mount['scratch-on-labstore1003']],
        }
    }

    labstore::nfs_mount { 'dumps-on-labstore1003':
        mount_name  => 'dumps',
        project     => $::labsproject,
        options     => ['ro', 'soft', 'timeo=300', 'retrans=3'],
        mount_path  => '/public/dumps',
        share_path  => '/dumps',
        server      => 'labstore1003.eqiad.wmnet',
        lookupcache => $lookupcache,
    }
}
