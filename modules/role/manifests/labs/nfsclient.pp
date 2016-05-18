class role::labs::nfsclient {

    include labstore::traffic_shaping

    file { [
            '/data',
            '/public',
        ]:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
    }

    # This script will block until the NFS volume is available
    file { '/usr/local/sbin/block-for-export':
        ensure  => present,
        owner   => root,
        mode    => '0555',
        source  => 'puppet:///modules/labstore/block-for-export',
    }

    if hiera('mount_nfs_hard_mode', true) {
        $mode = 'hard'
    } else {
        $mode = 'soft,timeo=10'
    }

    $nfs_opts = "vers=4,bg,${mode},intr,sec=sys,proto=tcp,port=0,noatime,lookupcache=none,nofsc"
    $nfs_server = 'labstore.svc.eqiad.wmnet'
    $dumps_server = 'labstore1003.eqiad.wmnet'

    # ideally this is only on NFS enabled hosts in the future
    diamond::collector { 'Nfsiostat':
        source  => 'puppet:///modules/diamond/collector/nfsiostat.py',
        require => Package['diamond'],
    }

    if mount_nfs_volume($::labsproject, 'home') {
        # Note that this is the same export as for /data/project
        exec { 'block-for-home-export':
            command => "/usr/local/sbin/block-for-export ${nfs_server} project/${::labsproject} 180",
            require => [File['/etc/modprobe.d/nfs-no-idmap.conf'], File['/usr/local/sbin/block-for-export']],
            unless  => '/bin/mountpoint -q /home',
        }

        mount { '/home':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "rw,${nfs_opts}",
            device  => "${nfs_server}:/project/${::labsproject}/home",
            require => [File['/etc/modprobe.d/nfs-no-idmap.conf'], Exec['block-for-home-export']],
        }
    }

    if mount_nfs_volume($::labsproject, 'project') {

        exec { 'block-for-project-export':
            command => "/usr/local/sbin/block-for-export ${nfs_server} project/${::labsproject} 180",
            require => [File['/etc/modprobe.d/nfs-no-idmap.conf'], File['/usr/local/sbin/block-for-export']],
            unless  => '/bin/mountpoint -q /data/project',
        }

        file { '/data/project':
            ensure  => directory,
            require => File['/data'],
        }

        mount { '/data/project':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "rw,${nfs_opts}",
            device  => "${nfs_server}:/project/${::labsproject}/project",
            require => [File['/data/project', '/etc/modprobe.d/nfs-no-idmap.conf'], Exec['block-for-project-export']],
        }
    }

    if mount_nfs_volume($::labsproject, 'scratch') {

        # We don't need to block for this one because it's always exported for everyone.
        file { '/data/scratch':
            ensure  => directory,
            require => File['/data'],
        }

        mount { '/data/scratch':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "rw,${nfs_opts}",
            device  => "${nfs_server}:/scratch",
            require => File['/data/scratch', '/etc/modprobe.d/nfs-no-idmap.conf'],
        }
    }

    if mount_nfs_volume($::labsproject, 'statistics') {

        file { '/public/statistics':
            ensure  => directory,
            require => File['/public'],
        }

        mount { '/public/statistics':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "ro,${nfs_opts}",
            device  => "${dumps_server}:/statistics",
            require => File['/public/statistics', '/etc/modprobe.d/nfs-no-idmap.conf'],
        }
    }

    if mount_nfs_volume($::labsproject, 'dumps') {

        file { '/public/dumps':
            ensure  => directory,
            require => File['/public'],
        }

        mount { '/public/dumps':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "ro,${nfs_opts}",
            device  => "${dumps_server}:/dumps",
            require => File['/public/dumps', '/etc/modprobe.d/nfs-no-idmap.conf'],
        }
    }

    # While the default on kernels >= 3.3 is to have idmap disabled,
    # doing so explicitly does no harm and ensures it is everywhere.
    file { '/etc/modprobe.d/nfs-no-idmap.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "options nfs nfs4_disable_idmapping=1\n",
    }

    file { '/etc/idmapd.conf':
        ensure => absent,
    }
}
