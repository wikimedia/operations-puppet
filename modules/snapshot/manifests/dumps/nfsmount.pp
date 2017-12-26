define snapshot::dumps::nfsmount(
    $mountpoint = undef,
    $server = undef,
) {
    require_package('nfs-common')

    file { [ $mountpoint ]:
        ensure => 'directory',
    }

    if ($server != undef) {
        mount { $mountpoint:
            ensure   => 'mounted',
            device   => "${server}:/data",
            fstype   => 'nfs',
            name     => $mountpoint,
            options  => 'bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3',
            require  => File[$mountpoint],
            remounts => false,
        }
    }
}
