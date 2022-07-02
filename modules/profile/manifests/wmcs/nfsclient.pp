# This relies on mount_nfs_volume.rb
# which whitelists hosts and mounts via yaml defined explicitly
# by project. That same yaml file is used on NFS servers
# to decide what to export.
class profile::wmcs::nfsclient(
    # Be careful with this setting. Switching to soft mount on a high-churn mount
    # may cause data corruption whenever there is a network or storage issue.
    String $mode = lookup('profile::wmcs::nfsclient::mode', {'default_value' => 'hard'}),
    # This is experimental and should be opt-in. /home on a busy server should be a hard mount.
    String $home_mode = lookup('profile::wmcs::nfsclient::home_mode', {'default_value' => 'hard'}),
    Pattern[/^4(:?\.[0-2])?$/] $nfs_version = lookup('profile::wmcs::nfsclient::nfs_version', {'default_value' => '4'}),
    Array[Stdlib::Host] $dumps_servers = lookup('dumps_dist_nfs_servers'),
    Stdlib::Host $dumps_active_server = lookup('dumps_dist_active_vps'),
) {
    $project_hostpath = mount_nfs_volume($::labsproject, 'project')
    $home_hostpath = mount_nfs_volume($::labsproject, 'home')
    $scratch_hostpath = mount_nfs_volume($::labsproject, 'scratch')
    $maps_hostpath = mount_nfs_volume($::labsproject, 'maps')

    if $project_hostpath {
        $project_host = split($project_hostpath, ':')[0]
        $project_path = split($project_hostpath, ':')[1]

        # TODO: Change these "secondary" mentions to "primary"
        # The primary cluster is mounted as secondary for historical reasons and
        # changing this would be quite disruptive so put off for a while.
        labstore::nfs_mount { 'project-on-labstore-secondary':
            mount_name  => 'project',
            project     => $::labsproject,
            options     => ['rw', $mode],
            mount_path  => '/mnt/nfs/labstore-secondary-project',
            share_path  => $project_path,
            server      => $project_host,
            nfs_version => $nfs_version,
        }

        file { '/data/project':
            ensure  => 'link',
            force   => true,
            target  => '/mnt/nfs/labstore-secondary-project',
            require => Labstore::Nfs_mount['project-on-labstore-secondary'],
        }
    }

    if $home_hostpath {
        $home_host = split($home_hostpath, ':')[0]
        $home_path = split($home_hostpath, ':')[1]

        labstore::nfs_mount { 'home-on-labstore-secondary':
            mount_name  => 'home',
            project     => $::labsproject,
            options     => ['rw', $home_mode],
            mount_path  => '/mnt/nfs/labstore-secondary-home',
            share_path  => $home_path,
            server      => $home_host,
            nfs_version => $nfs_version,
        }

        file { '/home':
            ensure  => 'link',
            force   => true,
            target  => '/mnt/nfs/labstore-secondary-home',
            require => Labstore::Nfs_mount['home-on-labstore-secondary'],
        }
    }

    if $scratch_hostpath {
        $scratch_host = split($scratch_hostpath, ':')[0]
        $scratch_path = split($scratch_hostpath, ':')[1]

        labstore::nfs_mount { 'scratch-on-secondary':
            mount_name  => 'scratch',
            project     => $::labsproject,
            options     => ['rw', 'soft', 'timeo=300', 'retrans=3'],
            mount_path  => '/mnt/nfs/secondary-scratch',
            server      => $scratch_host,
            share_path  => $scratch_path,
            nfs_version => $nfs_version,
        }

        file { '/data/scratch':
            ensure  => 'link',
            target  => '/mnt/nfs/secondary-scratch',
            require => Labstore::Nfs_mount['scratch-on-secondary'],
        }
    }

    if $::labsproject == 'toolsbeta' {
        # Sets up symlinks from new tools mounts to /data/project and /home
        if mount_nfs_volume($::labsproject, 'toolsbeta-project') {
            labstore::nfs_mount { 'toolsbeta-project-on-nfs-01':
                mount_name  => 'toolsbeta-project',
                project     => $::labsproject,
                options     => ['rw', $home_mode],
                mount_path  => '/mnt/nfs/nfs-01-toolsbeta-project',
                server      => 'toolsbeta-nfs.svc.toolsbeta.eqiad1.wikimedia.cloud',
                share_path  => '/srv/toolsbeta/misc/shared/toolsbeta/project/',
                nfs_version => $nfs_version,
            }

            file { '/data/project':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/nfs-01-toolsbeta-project',
                require => Labstore::Nfs_mount['toolsbeta-project-on-nfs-01'],
            }
        }
        if mount_nfs_volume($::labsproject, 'toolsbeta-home') {
            labstore::nfs_mount { 'toolsbeta-home-on-nfs-01':
                mount_name  => 'toolsbeta-home',
                project     => $::labsproject,
                options     => ['rw', $mode],
                mount_path  => '/mnt/nfs/nfs-01-toolsbeta-home',
                server      => 'toolsbeta-nfs.svc.toolsbeta.eqiad1.wikimedia.cloud',
                share_path  => '/srv/toolsbeta/misc/shared/toolsbeta/home/',
                nfs_version => $nfs_version,
            }

            file { '/home':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/nfs-01-toolsbeta-home',
                require => Labstore::Nfs_mount['toolsbeta-home-on-nfs-01'],
            }
        }
    }

    if $::labsproject == 'maps' {
        if $maps_hostpath {
            $maps_host = split($maps_hostpath, ':')[0]
            $maps_path = split($maps_hostpath, ':')[1]

            labstore::nfs_mount { 'maps-on-secondary':
                mount_name  => 'maps',
                project     => $::labsproject,
                options     => ['rw', $home_mode],  # Careful with mode on maps - /home is there
                mount_path  => '/mnt/nfs/secondary-maps',
                server      => $maps_host,
                share_path  => $maps_path,
                nfs_version => $nfs_version,
            }

            file { '/data/project':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/secondary-maps/project',
                require => Labstore::Nfs_mount['maps-on-secondary'],
            }
            file { '/home':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/secondary-maps/home',
                require => Labstore::Nfs_mount['maps-on-secondary'],
            }
        }
    }

    # Only set the $mode on tools where you really know what you are doing.
    # /data/project there is the home directory for tools so it should never
    # be set on the grid or most worker nodes. Only set that to soft when it is
    # a special purpose instance that uses it for backup or similar.
    if $::labsproject == 'tools' {
        # Sets up symlinks from new tools mounts to /data/project and /home
        if mount_nfs_volume($::labsproject, 'tools-project') {
            labstore::nfs_mount { 'tools-project-on-labstore-secondary':
                mount_name  => 'tools-project',
                project     => $::labsproject,
                options     => ['rw', $home_mode],
                mount_path  => '/mnt/nfs/labstore-secondary-tools-project',
                server      => 'nfs-tools-project.svc.eqiad.wmnet',
                share_path  => '/srv/tools/shared/tools/project',
                nfs_version => $nfs_version,
            }

            file { '/data/project':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore-secondary-tools-project',
                require => Labstore::Nfs_mount['tools-project-on-labstore-secondary'],
            }
        }
        if mount_nfs_volume($::labsproject, 'tools-home') {
            labstore::nfs_mount { 'tools-home-on-labstore-secondary':
                mount_name  => 'tools-home',
                project     => $::labsproject,
                options     => ['rw', $mode],
                mount_path  => '/mnt/nfs/labstore-secondary-tools-home',
                server      => 'nfs-tools-project.svc.eqiad.wmnet',
                share_path  => '/srv/tools/shared/tools/home',
                nfs_version => $nfs_version,
            }

            file { '/home':
                ensure  => 'link',
                force   => true,
                target  => '/mnt/nfs/labstore-secondary-tools-home',
                require => Labstore::Nfs_mount['tools-home-on-labstore-secondary'],
            }
        }
    }

    if mount_nfs_volume($::labsproject, 'dumps') {
        $dumps_servers.each |String $server| {
            labstore::nfs_mount { $server:
                mount_name  => 'dumps',
                project     => $::labsproject,
                options     => ['ro', 'soft', 'timeo=300', 'retrans=3'],
                mount_path  => "/mnt/nfs/dumps-${server}",
                server      => $server,
                nfs_version => $nfs_version,
            }
        }

        file { '/public/dumps':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        $dumps_share_root = "/mnt/nfs/dumps-${dumps_active_server}"

        $defaults = {
            ensure => 'link',
            require => Labstore::Nfs_mount[$dumps_active_server]
        }

        $symlinks = {
            '/public/dumps/public' => {
                target  => "${dumps_share_root}/",
            },
            '/public/dumps/incr' => {
                target  => "${dumps_share_root}/other/incr",
            },
            '/public/dumps/pagecounts-all-sites' => {
                target  => "${dumps_share_root}/other/pagecounts-all-sites",
            },
            '/public/dumps/pagecounts-raw' => {
                target  => "${dumps_share_root}/other/pagecounts-raw",
            },
            '/public/dumps/pageviews' => {
                target  => "${dumps_share_root}/other/pageviews",
            },
        }

        create_resources(file, $symlinks, $defaults)
    }
}
