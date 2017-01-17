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

    # Dual mount /project for misc (other) projects under /mnt/nfs/labstore-secondary-project
    labstore::nfs_mount { 'project-on-labstore-secondary':
        mount_name  => 'project',
        project     => $::labsproject,
        options     => ['rw', $mode],
        mount_path  => '/mnt/nfs/labstore-secondary-project',
        share_path  => "/project/${::labsproject}/project",
        server      => 'nfs-tools-project.svc.eqiad.wmnet',
        block       => true,
        lookupcache => $lookupcache,
    }

    # Dual mount /home for misc (other) projects under /mnt/nfs/labstore-secondary-home
    labstore::nfs_mount { 'home-on-labstore-secondary':
        mount_name  => 'home',
        project     => $::labsproject,
        options     => ['rw', 'hard'],
        mount_path  => '/mnt/nfs/labstore-secondary-home',
        share_path  => "/project/${::labsproject}/home",
        server      => 'nfs-tools-project.svc.eqiad.wmnet',
        block       => true,
        lookupcache => $lookupcache,
    }

    if $::labsproject == 'maps' {

        labstore::nfs_mount { 'maps-on-labstore1003':
            mount_name  => 'maps',
            project     => $::labsproject,
            options     => ['rw', 'hard'],
            mount_path  => '/mnt/nfs/labstore1003-maps',
            server      => 'labstore1003.eqiad.wmnet',
            share_path  => '/maps',
            lookupcache => $lookupcache,
        }

        if mount_nfs_volume($::labsproject, 'maps') {

            file { '/data/project':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore1003-maps/project',
                require => Labstore::Nfs_mount['maps-on-labstore1003'],
            }

            file { '/home':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore1003-maps/home',
                require => Labstore::Nfs_mount['maps-on-labstore1003'],
            }
        }
    }

    if $::labsproject == 'tools' {
        labstore::nfs_mount { 'tools-home-on-labstore-secondary':
            mount_name  => 'tools-home',
            project     => $::labsproject,
            options     => ['rw', 'hard'],
            mount_path  => '/mnt/nfs/labstore-secondary-tools-home',
            server      => 'nfs-tools-project.svc.eqiad.wmnet',
            share_path  => '/project/tools/home',
            lookupcache => $lookupcache,
        }

        labstore::nfs_mount { 'tools-project-on-labstore-secondary':
            mount_name  => 'tools-project',
            project     => $::labsproject,
            options     => ['rw', 'hard'],
            mount_path  => '/mnt/nfs/labstore-secondary-tools-project',
            server      => 'nfs-tools-project.svc.eqiad.wmnet',
            share_path  => '/project/tools/project',
            lookupcache => $lookupcache,
        }

        # Sets up symlinks from new tools mounts to /data/project and /home
        if mount_nfs_volume($::labsproject, 'tools-project') {
            file { '/data/project':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore-secondary-tools-project',
                require => Labstore::Nfs_mount['tools-project-on-labstore-secondary'],
            }
        }
        if mount_nfs_volume($::labsproject, 'tools-home') {
            file { '/home':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore-secondary-tools-home',
                require => Labstore::Nfs_mount['tools-home-on-labstore-secondary'],
            }
        }
    }

    labstore::nfs_mount { 'scratch-on-labstore1003':
        mount_name  => 'scratch',
        project     => $::labsproject,
        options     => ['rw', 'soft', 'timeo=300', 'retrans=3', 'nosuid', 'noexec', 'nodev'],
        mount_path  => '/mnt/nfs/labstore1003-scratch',
        server      => 'labstore1003.eqiad.wmnet',
        share_path  => '/scratch',
        lookupcache => $lookupcache,
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

    if mount_nfs_volume($::labsproject, 'scratch') {
        file { '/data/scratch':
            ensure  => 'link',
            target  => '/mnt/nfs/labstore1003-scratch',
            require => Labstore::Nfs_mount['scratch-on-labstore1003'],
        }
    }
}
