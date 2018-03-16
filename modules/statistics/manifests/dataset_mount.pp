# == Class statistics::dataset_mount
# Mounts /data from dataset1001 server.
# xmldumps and other misc files needed
# for generating statistics are here.
#
# NOTE: This class has nothing to do with the
# datasets site hosted at 'datasets.wikimedia.org'.
#
class statistics::dataset_mount {
    # need this for NFS mounts.
    require_package('nfs-common')

    file {'/mnt/nfs':
        ensure => 'directory',
    }

    file { '/mnt/nfs/README':
        ensure  => 'present',
        source  => 'puppet:///modules/statistics/dumps-nfsmount-readme.txt',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/mnt/nfs'],
    }

    file { '/mnt/nfs/labstore1006-dumps':
        ensure => 'directory',
    }

    file { '/mnt/nfs/labstore1007-dumps':
        ensure => 'directory',
    }

    mount { '/mnt/nfs/labstore1006-dumps':
        ensure  => 'mounted',
        device  => 'labstore1006.wikimedia.org:/dumps',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr',
        atboot  => true,
        require => File['/mnt/nfs/labstore1006-dumps'],
    }

    mount { '/mnt/nfs/labstore1007-dumps':
        ensure  => 'mounted',
        device  => 'labstore1007.wikimedia.org:/dumps',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr',
        atboot  => true,
        require => File['/mnt/nfs/labstore1007-dumps'],
    }


    file { '/mnt/data/':
        ensure  => 'link',
        target  => '/mnt/nfs/labstore1006-dumps',
        require => Mount['/mnt/nfs/labstore1006-dumps'],
    }

}
