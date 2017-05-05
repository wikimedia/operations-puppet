class snapshot::dumps::packages {
    require_package('mwbzutils')
    require_package('mysql-client')
    require_package('p7zip-full')
    require_package('nfs-common')
    require_package('rpcbind')

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
