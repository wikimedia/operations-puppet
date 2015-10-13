# nfs.pp

# Classes for NetApp mounts used on multiple servers

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

