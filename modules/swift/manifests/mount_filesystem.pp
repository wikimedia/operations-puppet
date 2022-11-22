# SPDX-License-Identifier: Apache-2.0
# @summary swift mount_point 
# @param mount_point_override explicitly set the mount oint
# @param use_label if true use a mount point label otherwise use the full title
define swift::mount_filesystem (
    Optional[Stdlib::Unixpath] $mount_point_override = undef,
    Boolean                    $use_label = true
) {
    $mount_base = '/srv/swift-storage'
    $dev_suffix  = regsubst($title, '^\/dev\/(.*)$', '\1')
    $mount_point = $mount_point_override.lest || { "${mount_base}/${dev_suffix}" }
    $device = $use_label.bool2str("LABEL=swift-${dev_suffix}", $title)

    # When the filesystem is _not_ mounted, its mountpoint permissions must not
    # allow 'swift' to write to it. Conversely, when the filesystem is mounted
    # then the owner must be 'swift' for things to work. The owning group stays
    # 'swift' with read+execute permissions to let swift-recon access the directory.
    # Note these checks are racy, as mountpoint status can change just after
    # checking, however it is a very small chance and will be likely rectified
    # at the next puppet run.
    exec { "mountpoint-root-${mount_point}":
        command  => "install -d -o root -g swift -m 750 ${mount_point}",
        provider => 'shell',
        onlyif   => [
          "! mountpoint -q ${mount_point}",
          "[ \"$( stat -c %U ${mount_point} )\" != \"root\" ]",
        ],
    }

    exec { "mountpoint-swift-${mount_point}":
        command  => "install -d -o swift -g swift -m 750 ${mount_point}",
        provider => 'shell',
        onlyif   => [
          "mountpoint -q ${mount_point}",
          "[ \"$( stat -c %U ${mount_point} )\" != \"swift\" ]",
        ],
    }

    # nobarrier for xfs has been removed in linux 4.19
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=1c02d502c20809a2a5f71ec16a930a61ed779b81
    $mount_options = (versioncmp($facts['kernelversion'], '4.19') >= 0) ? {
      true    => 'nofail,noatime,nodiratime,logbufs=8',
      default => 'nofail,noatime,nodiratime,nobarrier,logbufs=8',
    }

    mount { $mount_point:
        # XXX this won't mount the disks the first time they are added to
        # fstab.
        # We don't want puppet to keep the FS mounted, otherwise
        # it would conflict with swift-drive-auditor trying to keep FS
        # unmounted.
        ensure   => present,
        device   => $device,
        name     => $mount_point,
        fstype   => 'xfs',
        options  => $mount_options,
        atboot   => true,
        remounts => true,
    }
}
