define swift::mount_filesystem (
    $mount_base = '/srv/swift-storage',
){
    $dev         = $title
    $dev_suffix  = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $mount_point = "${mount_base}/${dev_suffix}"

    mount { $mount_point:
        # note we don't ensure => mounted to avoid puppet and
        # swift-drive-audit bouncing mount/unmount respectively
        ensure   => present,
        device   => "LABEL=swift-${dev_suffix}",
        name     => $mount_point,
        fstype   => 'xfs',
        options  => 'nobootwait,noatime,nodiratime,nobarrier,logbufs=8',
        atboot   => true,
        remounts => true,
    }

    # attempt to mount the FS only if there's a corresponding line
    # e.g. if swift-drive-auditor hasn't found the drive faulty
    # as a bonus, this makes puppet fail in case of unmountable file
    # systems
    exec { "mount-${mount_point}":
        command => "/bin/mount ${mount_point}",
        onlyif  => "/bin/grep -q '^LABEL=swift-${dev_suffix}' /etc/fstab",
        require => Mount[$mount_point],
    }

    # fix FS permissions, not permissions of the mountpoint
    exec { "perms-${mount_point}":
        command => "/usr/bin/install -d -o swift -g swift -m 0750 ${mount_point}",
        onlyif  => "/bin/mountpoint -q ${mount_point}",
        require => Mount[$mount_point],
    }
}
