define swift::mount_filesystem (
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

    # nobarrier for xfs has been removed in buster / linux 4.19
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=1c02d502c20809a2a5f71ec16a930a61ed779b81
    if os_version('debian <= stretch') {
      $mount_options = 'nofail,noatime,nodiratime,nobarrier,logbufs=8'
    } else {
      $mount_options = 'nofail,noatime,nodiratime,logbufs=8'
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
        options  => $mount_options,
        atboot   => true,
        remounts => true,
    }
}
