# nfs.pp

# Virtual resource for the monitoring server
#@monitoring::group { "nfs": description => "NFS" }

class nfs::common {
    package { 'nfs-common':
        ensure => 'latest',
    }
}

# Classes for NetApp mounts used on multiple servers

class nfs::netapp::common {
    include nfs::common

    $device = $::site ? {
        'eqiad' => 'nas1001-a.eqiad.wmnet',
        'codfw' => 'nas2001-a.codfw.wmnet',
        default => undef,
    }

    $options = 'bg,intr'
}

class nfs::netapp::home($ensure='mounted', $mountpoint='/home', $mount_site=$::site) {
    include common

    file { $mountpoint:
        ensure => 'directory',
    }

    mount { $mountpoint:
        ensure  => $ensure,
        require => File[$mountpoint],
        device  => "${nfs::netapp::common::device}:/vol/home_${mount_site}",
        fstype  => 'nfs',
        options => $nfs::netapp::common::options,
    }
}

class nfs::netapp::home::othersite($ensure='mounted', $mountpoint=undef) {
    include common

    $peersite = $::site ? {
        'eqiad' => 'codfw',
        'codfw' => 'eqiad',
        default => undef
    }
    $path = $mountpoint ? {
        undef   => "/srv/home_${peersite}",
        default => $mountpoint
    }

    file { $path:
        ensure => 'directory',
    }

    mount { $path:
        ensure  => $ensure,
        require => File[$path],
        device  => "${nfs::netapp::common::device}:/vol/home_${peersite}",
        fstype  => 'nfs',
        options => "${nfs::netapp::common::options},ro",
    }
}

class nfs::data {
    include nfs::common

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

    include common

    file { $mountpoint:
        ensure => 'directory',
    }

    mount { $mountpoint:
        ensure  => $ensure,
        require => File[$mountpoint],
        device  => "${nfs::netapp::common::device}:/vol/fr_archive",
        fstype  => 'nfs',
        options => $nfs::netapp::common::options,
    }
}

