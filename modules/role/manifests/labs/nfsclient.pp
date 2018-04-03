class role::labs::nfsclient(
    $mode = 'hard',
    $lookupcache = 'all',
) {

    labstore::nfs_mount { 'project-on-labstore-secondary':
        mount_name  => 'project',
        project     => $::labsproject,
        options     => ['rw', $mode],
        mount_path  => '/mnt/nfs/labstore-secondary-project',
        share_path  => "/project/${::labsproject}/project",
        server      => 'nfs-tools-project.svc.eqiad.wmnet',
        lookupcache => $lookupcache,
    }

    labstore::nfs_mount { 'home-on-labstore-secondary':
        mount_name  => 'home',
        project     => $::labsproject,
        options     => ['rw', 'hard'],
        mount_path  => '/mnt/nfs/labstore-secondary-home',
        share_path  => "/project/${::labsproject}/home",
        server      => 'nfs-tools-project.svc.eqiad.wmnet',
        lookupcache => $lookupcache,
    }

    if mount_nfs_volume($::labsproject, 'project') {
        file { '/data/project':
            ensure  => 'link',
            force   => true,
            target  => '/mnt/nfs/labstore-secondary-project',
            require => Labstore::Nfs_mount['project-on-labstore-secondary'],
        }
    }

    if mount_nfs_volume($::labsproject, 'home') {
        file { '/home':
            ensure  => 'link',
            force   => true,
            target  => '/mnt/nfs/labstore-secondary-home',
            require => Labstore::Nfs_mount['home-on-labstore-secondary'],
        }
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

    if mount_nfs_volume($::labsproject, 'scratch') {
        file { '/data/scratch':
            ensure  => 'link',
            target  => '/mnt/nfs/labstore1003-scratch',
            require => Labstore::Nfs_mount['scratch-on-labstore1003'],
        }
    }

    $dumps_servers = hiera('dumps_dist_nfs_servers')

    $dumps_servers.each |String $server| {
        labstore::nfs_mount { $server:
            mount_name  => 'dumps',
            project     => $::labsproject,
            options     => ['ro', 'soft', 'timeo=300', 'retrans=3'],
            mount_path  => "/mnt/nfs/dumps-${server}",
            share_path  => '/dumps',
            server      => $server,
            lookupcache => $lookupcache,
        }
    }

    if mount_nfs_volume($::labsproject, 'dumps') {

        file { '/public/dumps':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        $dumps_active_server = hiera('dumps_dist_active_vps')
        $dumps_share_root = "/mnt/nfs/dumps-${dumps_active_server}/xmldatadumps"

        $defaults = {
            ensure => 'link',
            require => Labstore::Nfs_mount[$dumps_active_server]
        }

        $symlinks = {
            '/public/dumps/public' => {
                target  => "${dumps_share_root}/public",
            },
            '/public/dumps/incr' => {
                target  => "${dumps_share_root}/incr",
            },
            '/public/dumps/pagecounts-all-sites' => {
                target  => "${dumps_share_root}/public/other/pagecounts-all-sites",
            },
            '/public/dumps/pagecounts-raw' => {
                target  => "${dumps_share_root}/public/other/pagecounts-raw",
            },
            '/public/dumps/pageviews' => {
                target  => "${dumps_share_root}/public/other/pageviews",
            },
        }

        create_resources(file, $symlinks, $defaults)
    }
}
