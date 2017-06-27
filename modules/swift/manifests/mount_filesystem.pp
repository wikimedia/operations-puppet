define swift::mount_filesystem (
    $mount_base = '/srv/swift-storage',
){
    if ($title !~ /^[hvs]d[a-z]+[0-9]+$/) {
        fail("Invalid name ${title} for swift::mount_filesystem")
    }

    $mount_point = "${mount_base}/${title}"

    file { "mountpoint-${mount_point}":
        ensure => directory,
        path   => $mount_point,
        owner  => 'swift',
        group  => 'swift',
        mode   => '0750',
    }

    # systemd < 218-4 fails to handle 'nobootwait' in fstab
    # http://metadata.ftp-master.debian.org/changelogs/main/s/systemd/unstable_changelog
    if $::operatingsystem == 'Ubuntu' and os_version('ubuntu <= trusty') {
        $mount_options = 'nobootwait,noatime,nodiratime,nobarrier,logbufs=8'
    } else {
        $mount_options = 'nofail,noatime,nodiratime,nobarrier,logbufs=8'
    }

    mount { $mount_point:
        # XXX this won't mount the disks the first time they are added to
        # fstab.
        # We don't want puppet to keep the FS mounted, otherwise
        # it would conflict with swift-drive-auditor trying to keep FS
        # unmounted.
        ensure   => present,
        device   => "LABEL=swift-${title}",
        name     => $mount_point,
        fstype   => 'xfs',
        options  => $mount_options,
        atboot   => true,
        remounts => true,
    }
}
