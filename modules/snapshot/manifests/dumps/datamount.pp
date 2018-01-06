define snapshot::dumps::datamount(
    $mountpoint = undef,
    $mount_type = undef,
    $server = undef,
    $managed_subdirs = [],
    $user = undef,
    $group = undef,
) {
    if ($mount_type == 'local' or $mount_type == 'nfs') {
        file { [ $mountpoint ]:
            ensure => 'directory',
        }
    }
    elsif ($mount_type == 'labslvm') {
        labs_lvm::volume { 'data-local-disk':
            mountat => $mountpoint,
        }
    }

    if ($mount_type == 'nfs') {
        require_package('nfs-common')

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

    if (defined($managed_subdirs) and $managed_subdirs) {
        file { $managed_subdirs:
            ensure => 'directory',
            mode   => '0755',
            owner  => $user,
            group  => $group,
        }
    }
}
