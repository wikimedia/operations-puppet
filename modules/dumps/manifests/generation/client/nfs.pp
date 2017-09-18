class dumps::generation::client::nfs {
    require_package('nfs-common')

    file { [ '/mnt/dumpsdata' ]:
        ensure => 'directory',
    }

    $dumpsdataserver = $::site ? {
        'eqiad' => 'dumpsdata1001.eqiad.wmnet',
        default => 'dumpsdata1001.eqiad.wmnet',
    }

    mount { '/mnt/dumpsdata':
        ensure   => 'mounted',
        device   => "${dumpsdataserver}:/data",
        fstype   => 'nfs',
        name     => '/mnt/dumpsdata',
        options  => 'bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3',
        require  => File['/mnt/dumpsdata'],
        remounts => false,
    }
}
