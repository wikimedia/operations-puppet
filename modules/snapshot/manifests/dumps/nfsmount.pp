define snapshot::dumps::nfsmount(
    $mountpoint = undef,
    $server = undef,
    $managed_subdirs = [],
    $user = undef,
    $group = undef,
) {
    require_package('nfs-common')

    file { [ $mountpoint ]:
        ensure => 'directory',
    }

    if (defined($server)) {
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
    else {
        # manage some directories that the nfs server
        # server would otherwise take care of for us
        file { $managed_subdirs:
            ensure => 'directory',
            mode   => '0755',
            owner  => $user,
            group  => $group,
        }
    }
}
