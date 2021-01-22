define snapshot::dumps::datamount(
    $mountpoint = undef,
    $mount_type = undef,
    $server = undef,
    $managed_subdirs = [],
    $extra_mountopts = undef,
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

    $standard_mountopts = 'bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3'
    if ($extra_mountopts != '') {
        $mountopts = "${standard_mountopts},${extra_mountopts}"
    } else {
        $mountopts = $standard_mountopts
    }
    if ($mount_type == 'nfs') {
        ensure_packages(['nfs-common'])

        mount { $mountpoint:
            ensure   => 'mounted',
            device   => "${server}:/data",
            fstype   => 'nfs',
            name     => $mountpoint,
            options  => $mountopts,
            require  => File[$mountpoint],
            remounts => false,
        }
    }

    if ($managed_subdirs) {
        file { $managed_subdirs:
            ensure => 'directory',
            mode   => '0755',
            owner  => $user,
            group  => $group,
        }
    }
}
