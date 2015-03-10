define swift_new::mount_filesystem (
    $mount_base = '/srv/swift-storage',
){
    $dev         = $title
    $dev_suffix  = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $mount_point = "${mount_base}/${dev_suffix}"

    file { "mountpoint-${mount_point}":
        ensure => directory,
        path   => $mount_point,
        owner  => 'swift',
        group  => 'swift',
        mode   => '0750',
    }

    mount { $mount_point:
        # XXX this won't mount the disks the first time they are added to
        # fstab.
        # We don't want puppet to keep the FS mounted, otherwise
        # it would conflict with swift-drive-auditor trying to keep FS
        # unmounted.
        ensure   => present,
        device   => "LABEL=swift-${dev_suffix}",
        name     => $mount_point,
        fstype   => 'xfs',
        options  => 'noatime,nodiratime,nobarrier,logbufs=8',
        atboot   => true,
        remounts => true,
    }
}
