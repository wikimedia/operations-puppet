# nfs.pp

# Classes for NetApp mounts used on multiple servers

class nfs::data {
    require_package('nfs-common')

    file { [ '/mnt/data' ]:
        ensure => 'directory',
    }

        $datasetserver = $::site ? {
            'eqiad' => 'dataset1001.wikimedia.org',
            default => 'dataset1001.wikimedia.org',
        }

    mount { '/mnt/data':
        ensure   => 'mounted',
        device   => "${datasetserver}:/data",
        fstype   => 'nfs',
        name     => '/mnt/data',
        options  => 'bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3',
        require  => File['/mnt/data'],
        remounts => false,
    }
}

class nfs::netapp::fr_archive(
        $ensure= 'mounted',
        $mountpoint= '/archive/udplogs'
    ) {

    require_package('nfs-common')

    $device = $::site ? {
        'eqiad' => 'nas1001-a.eqiad.wmnet',
        'codfw' => 'nas2001-a.codfw.wmnet',
        default => undef,
    }

    $options = 'bg,intr'

    file { $mountpoint:
        ensure => 'directory',
    }

    mount { $mountpoint:
        ensure  => $ensure,
        require => File[$mountpoint],
        device  => "${device}:/vol/fr_archive",
        fstype  => 'nfs',
        options => $options,
    }
}

