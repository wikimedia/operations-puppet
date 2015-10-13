class snapshot::common {
    include standard
    include snapshot::packages
    include mediawiki::scap

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
